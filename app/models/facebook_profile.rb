class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps
  include ApiHelpers::FacebookApiAccessor
  include Computations::FacebookProfileComputations

  attr_accessible :uid, :name, :image, :token, :token_expires, :token_expires_at

  field :uid,              type: Integer
  field :name,             type: String
  field :image,            type: String
  field :token,            type: String
  field :api_key,          type: String
  field :token_expires,    type: Boolean
  field :token_expires_at, type: DateTime
  field :last_fetched_at,  type: DateTime

  belongs_to :user, autosave: true, index: true

  validates :user_id, :api_key, :token, presence: true

  index [:uid, :api_key], unique: true
  index [:token, :api_key], unique: true
  index [:name, :api_key]

  has_one :facebook_graph, dependent: :destroy  # use the method facebook_graph_lightweight if you don't want the gexf file

  has_one :photo_engagements, autosave: true, as: :engagements, class_name: 'PhotoEngagements', inverse_of: :facebook_profile
  has_one :status_engagements, autosave: true, as: :engagements, class_name: 'StatusEngagements', inverse_of: :facebook_profile

  # All the records for a given profile that match the UID
  scope :profile_variants, lambda { |fp| where(uid: fp.uid) }

  def facebook_graph_lightweight
    FacebookGraph.where(facebook_profile_id: self.id).without(:gexf).first
  end

  def has_graph?
    FacebookGraph.where(facebook_profile_id: self.id).where(:gexf.exists => true).without(:gexf).exists?
  end

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
  # uid:              Facebook UID
  # api_key:          trust.cc API key
  # token:            Facebook OAuth token, when record is to be created
  # name:             Name of user (String, optional)
  # image:            Image of user (String (url), optional)
  # token_expires:    From FB OAuth response (boolean, optional)
  # token_expires_at: From OmniAuth (DateTime, optional)
  def self.find_or_create_by_uid_and_api_key(params)
    params = params.with_indifferent_access.slice(:uid, :api_key, :token, :name, :image, :token_expires, :token_expires_at)
    raise ArgumentError.new(':uid and :api_key parameters are required!') if params[:uid].blank? || params[:api_key].blank?

    fp = FacebookProfile.where(params.slice(:uid, :api_key)).first
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

  #def email
  #  self.info['email']
  #end
  #
  #def current_location_name
  #  self.info['location']['name']
  #end

end

