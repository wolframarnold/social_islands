class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps
  include ApiHelpers::FacebookApiAccessor
  include Computations::FacebookProfileComputations

  # High-level/common use profile fields
  field :uid,              type: Integer
  field :name,             type: String
  field :image,            type: String
  field :token,            type: String
  field :app_id,           type: String
  field :token_expires,    type: Boolean
  field :token_expires_at, type: DateTime

  # Last FB contact
  field :fetched_directly, type: Boolean, default: false  # direct download, vs. indirect (through friends)
  field :last_fetched_at,  type: DateTime
  field :last_fetched_by,  type: Integer  # FB UID of user who caused the record to be populated
                                          # can be user him/herself (direct login) or another user (data retrieved as friend record)

  # For notifying client on fetch & computation completion
  field :postback_url,     type: String

  # High-level scores -- detailed stats in computed_stats field
  field :profile_authenticity, type: Float
  field :trust_score, type: Float

  # Computed entities, intermediate scores, etc. -- all (re-)computable from raw data
  # Used by module: Computations::FacebookProfileComputations
  field :computed_stats,       type: Hash, default: {}
  field :last_computed_at,     type: DateTime
  field :photo_engagements,    type: Hash, default: {}
  field :status_engagements,   type: Hash, default: {}
  field :location_engagements, type: Hash, default: {}
  field :tagged_engagements,   type: Hash, default: {}
  field :profile_completeness, type: Float

  # Raw data fields from Facebook
  # Used by module: ApiHelpers::FacebookApiAccessor
  field :photos,            type: Array, default: []
  field :tagged,            type: Array, default: []
  field :posts,             type: Array, default: []
  field :locations,         type: Array, default: []
  field :statuses,          type: Array, default: []
  field :likes,             type: Array, default: []
  field :checkins,          type: Array, default: []
  field :feed,              type: Array, default: []
  field :permissions,       type: Array, default: []
  field :joined_on,         type: Date
  field :about_me,          type: Hash
  field :edge_count,        type: Integer, default: 0

  field :facebook_profile_uids, type: Array, default: []  # for friends

  field :facebook_api_error, type: String

  belongs_to :user, autosave: true, index: true

  validates :user_id, :app_id, presence: true
  validates :token, presence: true, if: :fetching_directly

  validate :postback_url_matched_domain

  index [[:uid, Mongo::ASCENDING], [:app_id, Mongo::ASCENDING]]
  index [[:token, Mongo::ASCENDING], [:app_id, Mongo::ASCENDING]]
  index [[:name, Mongo::ASCENDING], [:app_id, Mongo::ASCENDING]]
  index [[:app_id, Mongo::ASCENDING], [:fetched_directly, Mongo::ASCENDING]]

  has_one :facebook_graph, dependent: :destroy  # use the method facebook_graph_lightweight if you don't want the gexf file

  # All the records for a given profile that match the UID
  scope :profile_variants, lambda { |fp| where(uid: fp.uid) }

  scope :dashboard_index, lambda {|app_id| where(app_id: app_id, fetched_directly: true) }

  attr_protected :app_id, :profile_authenticity, :trust_score, :computed_stats,
                 :photo_engagements, :status_engagements, :profile_completeness

  attr_accessor :fetching_directly  # process flag -- indicated whether the record is being fetched directly or not, but not whether it succeeded


  def facebook_graph_lightweight
    FacebookGraph.where(facebook_profile_id: self.id).without(:gexf).first
  end

  def has_graph?
    FacebookGraph.where(facebook_profile_id: self.id).where(:gexf.exists => true).without(:gexf).exists?
  end

  def has_scores?
    profile_authenticity.present?
  end

  def self.updatable_attributes
    %w(facebook_id uid token name image token_expires token_expires_at postback_url fetching_directly)
  end

  # required params:
  # app_id:      trust.cc APP ID for authorized client
  # and one of:
  # token:       OAuth token
  # facebook_id: UID for Facebook record
  #
  # optional params:
  # postback_url -- where to post back to when score is computed
  def self.update_or_create_by_token_or_facebook_id_and_app_id(params)
    params = params.with_indifferent_access

    if params[:app_id].blank? || (params[:token].blank? && params[:facebook_id].blank?)
      raise ArgumentError.new("'app_id' and 'token' or 'facebook_id' parameters are required!")
    elsif params[:token].blank?
      self.update_or_create_by_facebook_id_and_app_id(params)
    else  # got token -- takes precedence over facebook_id
      fp = FacebookProfile.where(params.slice(:token, :app_id)).first
      if fp.present?
        fp.update_attributes(params.slice(*updatable_attributes))
        fp
      else
        params.merge! self.get_facebook_id_name_image(params[:token])  # FB API call to get UID, name, image from token
        self.update_or_create_by_facebook_id_and_app_id(params)
      end
    end
  end

  # required params:
  # facebook_id:      Facebook UID
  # uid:              Facebook UID (also accepted by this key only in this method!)
  # app_id:           trust.cc APP ID
  # optional params:
  # token:            Facebook OAuth token, when record is to be created
  # name:             Name of user (String, optional)
  # image:            Image of user (String (url), optional)
  # token_expires:    From FB OAuth response (boolean, optional)
  # token_expires_at: From OmniAuth (DateTime, optional)
  # postback_url:     From client, Where to post back to when score is computed
  def self.update_or_create_by_facebook_id_and_app_id(params)
    params = params.with_indifferent_access
    params[:facebook_id] = params[:uid] if params[:facebook_id].blank? && params[:uid].present?
    raise ArgumentError.new(':facebook_id and :app_id parameters are required!') if params[:facebook_id].blank? || params[:app_id].blank?

    fp = FacebookProfile.where(uid: params[:facebook_id], app_id: params[:app_id]).first
    if fp.nil?
      fp = self.new(params.slice(*updatable_attributes))
      fp.app_id = params[:app_id]  # not mass-assignable for spoofing protection
      if fp_with_same_facebook_id = FacebookProfile.where(uid: params[:facebook_id]).first
        fp.user_id = fp_with_same_facebook_id.user_id
      else
        fp.user = User.new params.slice(:name, :image) # fp.build_user -- throws method_missing error for some reason?
      end
    else
      fp.attributes = params.slice(*updatable_attributes)
    end
    fp.save
    fp
  end

  # The outside API's use :facebook_id as key
  def facebook_id=(uid)
    self.uid = uid
  end

  # We should fetch if (a) we've not fetched ever (no last_fetched_at timestamp)
  # or the record was fetched through a friend previously and not directly
  def should_fetch?
    last_fetched_at.nil? or !fetched_directly? or facebook_api_error.present?
  end

  private

  def postback_url_matched_domain
    if postback_url_changed?
      api_client = ApiClient.where(app_id: app_id).first
      domain = api_client.postback_domain
      if domain.blank? || postback_url_mis_matches(domain)
        api_client.update_from_api_manager
        domain = api_client.postback_domain
      end
      if domain.blank?
        errors.add(:postback_url, "requires a 'postback_domain' on file. Cannot use postback mechanism without it. Configure it on API dashboard.")
      elsif postback_url_mis_matches(domain)
        errors.add(:postback_url, "does not match 'postback_domain' on file. Postback mechanism disallowed.")
      end
    end
  end

  def postback_url_mis_matches(domain)
    postback_url !~ %r(https?://#{domain})
  end
end

