class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps
  include ApiHelpers::FacebookApiAccessor
  include Computations::FacebookProfileComputations

  attr_accessible :uid, :name, :image, :token, :token_expires, :token_expires_at, :postback_url, :facebook_id

  # High-level/common use profile fields
  field :uid,              type: Integer
  field :name,             type: String
  field :image,            type: String
  field :token,            type: String
  field :api_key,          type: String
  field :token_expires,    type: Boolean
  field :token_expires_at, type: DateTime

  index :uid, unique: true
  index :name

  # Last FB contact
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
  field :computed_stats,     type: Hash
  field :photo_engagements,  type: Hash
  field :status_engagements, type: Hash

  # Raw data fields from Facebook
  # Used by module: ApiHelpers::FacebookApiAccessor
  field :photos,            type: Array
  field :tagged,            type: Array
  field :posts,             type: Array
  field :locations,         type: Array
  field :statuses,          type: Array
  field :likes,             type: Array
  field :checkins,          type: Array
  field :permissions,       type: Hash
  field :joined_on,         type: Date
  field :about_me,          type: Hash
  field :edge_count,        type: Integer
  field :can_post,          type: Array, default: []  # UID's where self has permission to make wall posts

  field :facebook_profile_uids, type: Array, default: []  # for friends

  field :facebook_api_error, type: String
  field :fields_via_friend,  type: Hash  # profile fields obtains via a friend's permissions

  belongs_to :user, autosave: true, index: true

  validates :user_id, :api_key, :token, presence: true

  validate :postback_url_matched_domain

  index [:uid, :api_key], unique: true
  index [:token, :api_key], unique: true
  index [:name, :api_key]

  has_one :facebook_graph, dependent: :destroy  # use the method facebook_graph_lightweight if you don't want the gexf file

  # All the records for a given profile that match the UID
  scope :profile_variants, lambda { |fp| where(uid: fp.uid) }


  def facebook_graph_lightweight
    FacebookGraph.where(facebook_profile_id: self.id).without(:gexf).first
  end

  def has_graph?
    FacebookGraph.where(facebook_profile_id: self.id).where(:gexf.exists => true).without(:gexf).exists?
  end

  def has_scores?
    profile_authenticity.present?
  end

  # required params:
  # api_key: trust.cc API key for authorized client
  # and one of:
  # token:       OAuth token
  # facebook_id: UID for Facebook record
  #
  # optional params:
  # postback_url -- where to post back to when score is computed
  def self.update_or_create_by_token_or_facebook_id_and_api_key(params)
    params = params.with_indifferent_access

    if params[:api_key].blank? || (params[:token].blank? && params[:facebook_id].blank?)
      raise ArgumentError.new("'api_key' and 'token' or 'facebook_id' parameters are required!")
    elsif params[:token].blank?
      self.update_or_create_by_facebook_id_and_api_key(params)
    else  # got token -- takes precedence over facebook_id
      fp = FacebookProfile.where(params.slice(:token, :api_key)).first
      if fp.present?
        fp.update_attributes(params)
        fp
      else
        params.merge! self.get_facebook_id_name_image(params[:token])  # FB API call to get UID, name, image from token
        self.update_or_create_by_facebook_id_and_api_key(params)
      end
    end
  end

  # required params:
  # facebook_id:      Facebook UID
  # uid:              Facebook UID (also accepted by this key only in this method!)
  # api_key:          trust.cc API key
  # optional params:
  # token:            Facebook OAuth token, when record is to be created
  # name:             Name of user (String, optional)
  # image:            Image of user (String (url), optional)
  # token_expires:    From FB OAuth response (boolean, optional)
  # token_expires_at: From OmniAuth (DateTime, optional)
  # postback_url:     From client, Where to post back to when score is computed
  def self.update_or_create_by_facebook_id_and_api_key(params)
    params = params.with_indifferent_access
    params[:facebook_id] = params[:uid] if params[:facebook_id].blank? && params[:uid].present?
    raise ArgumentError.new(':facebook_id and :api_key parameters are required!') if params[:facebook_id].blank? || params[:api_key].blank?

    fp = FacebookProfile.where(uid: params[:facebook_id], api_key: params[:api_key]).first
    if fp.nil?
      fp = self.new(params.except(:api_key))
      fp.api_key = params[:api_key]  # not mass-assignable for spoofing protection
      if fp_with_same_facebook_id = FacebookProfile.where(uid: params[:facebook_id]).first
        fp.user_id = fp_with_same_facebook_id.user_id
      else
        fp.user = User.new params.slice(:name, :image) # fp.build_user -- throws method_missing error for some reason?
      end
    else
      fp.attributes = params
    end
    fp.save
    fp
  end

  # The outside API's use :facebook_id as key
  def facebook_id=(uid)
    self.uid = uid
  end

  #def email
  #  self.info['email']
  #end
  #
  #def current_location_name
  #  self.info['location']['name']
  #end

  private

  def postback_url_matched_domain
    if postback_url_changed?
      domain = ApiClient.where(api_key: api_key).first.try(:postback_domain)
      if domain.blank?
        errors.add(:postback_url, "requires a 'postback_domain' on file. Cannot use postback mechanism without it. Configure it on API dashboard.")
      elsif postback_url !~ %r(https?://#{domain})
        errors.add(:postback_url, "does not match 'postback_domain' on file. Postback mechanism disallowed.")
      end
    end
  end

end

