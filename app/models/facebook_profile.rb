class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps
  include ApiHelpers::FacebookApiAccessor
  include Computations::FacebookProfileComputations

  attr_accessible :uid, :name, :image, :token

  field :token,   type: String
  field :api_key, type: String

  belongs_to :user, autosave: true, index: true

  validates :user_id, :api_key, :token, presence: true

  index [:uid, :api_key], unique: true
  index [:token, :api_key], unique: true

  embeds_many :labels, inverse_of: :facebook_profile

  has_one :photo_engagements, autosave: true, as: :engagements, class_name: 'PhotoEngagements', inverse_of: :facebook_profile
  has_one :status_engagements, autosave: true, as: :engagements, class_name: 'StatusEngagements', inverse_of: :facebook_profile

  # All the records for a given profile that match the UID
  scope :profile_variants, lambda { |fp| where(uid: fp.uid) }

  def friends_variants
    uids = FacebookFriendship.from(self).only(:facebook_profile_to_uid).map(&:facebook_profile_to_uid)
    self.class.any_in(uid: uids)
  end

  def friendships
    FacebookFriendship.from(self)
  end

  #HEAVY_FIELDS = [:friends, :edges, :graph, :histogram_num_connections]

  #default_scope without(HEAVY_FIELDS)
  #scope :graph_only, unscoped.only(:graph)
  #scope :friends_only, unscoped.only(:friends)

  # expected params:
  # token:   OAuth token
  # api_key: trust.cc API key for authorized client
  def self.find_or_create_by_token_and_api_key(params)
    params = params.with_indifferent_access.slice(:token, :api_key)
    raise ArgumentError.new(':token and :api_key parameters are required!') if params[:token].blank? || params[:api_key].blank?

    fp = FacebookProfile.where(params).first
    return fp unless fp.nil?

    params.merge! self.get_uid_name_image(params[:token])  # FB API call to get UID, name, image from token
    self.find_or_create_by_uid_and_api_key(params)
  end

  # expected params:
  # uid:     Facebook UID
  # api_key: trust.cc API key
  # token:   Facebook OAuth token, when record is to be created
  # name:    Name of user (optional)
  # image:   Image of user (optional)
  def self.find_or_create_by_uid_and_api_key(params)
    params = params.with_indifferent_access.slice(:uid, :api_key, :token, :name, :image)
    raise ArgumentError.new(':uid and :api_key parameters are required!') if params[:uid].blank? || params[:api_key].blank?

    fp = FacebookProfile.where(params.except(:token)).first
    if fp.nil?
      fp = self.new(params.except(:api_key))
      fp.api_key = params[:api_key]  # not mass-assignable for spoofing protection
      if fp_with_same_uid = FacebookProfile.where(uid: params[:uid]).first
        fp.user_id = fp_with_same_uid.user_id
      else
        fp.user = User.new params.slice(:name, :image) # fp.build_user -- throws method_missing error for some reason?
      end
      fp.save
    end
    fp
  end


  ## 1. Look up by token.
  ## 2. If that fails, go to FB and get UID then try to find record by UID.
  ## 3. If that fails, too, then we assume we don't have the record yet -> create new.
  #def self.find_or_create_by_token(token)
  #  user = User.where(token: token, provider: 'facebook').first
  #
  #  if user.nil?
  #    uid = FacebookProfile.get_uid(token)
  #
  #    # TODO: Use Mongoid 3.0's find_and_modify here to make the user lookup and update atomic
  #    user = User.where(uid: uid, provider: 'facebook').first
  #  end
  #
  #  if user.nil?
  #    user = User.new(uid: uid, provider: 'facebook')
  #    user.token = token
  #    fb_profile = user.build_facebook_profile(uid: uid)
  #    user.save
  #  else
  #    user.update_attribute(:token, token)
  #    fb_profile = user.facebook_profile || user.create_facebook_profile(uid: uid)
  #  end
  #
  #  fb_profile
  #end

  #def email
  #  self.info['email']
  #end
  #
  #def current_location_name
  #  self.info['location']['name']
  #end

  # We're not loading graph nor edges nor friends by default, because they're very
  # large and expensive. So, to query if the graph is present we need to run
  # a DB query, without loading the attribute, though. Mongo is good at this...
  #def has_graph?
  #  graph.present? || self.class.unscoped.where(:_id => self.to_param, :graph.ne => nil).exists?
  #end
  #
  #def has_edges?
  #  edges.present? || self.class.unscoped.where(:_id => self.to_param, :edges.ne => nil).exists?
  #end
  #

end

