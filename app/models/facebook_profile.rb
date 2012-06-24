class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps
  include ApiHelpers::FacebookApiAccessor
  include Computations::FacebookProfileComputations

  attr_accessible :uid, :name, :image

  belongs_to :user

  validates :user_id, presence: true

  index :user_id, unique: true
  index :uid, unique: true

  embeds_many :labels, inverse_of: :facebook_profile

  has_one :photo_engagements, autosave: true, as: :engagements, class_name: 'PhotoEngagements', inverse_of: :facebook_profile
  has_one :status_engagements, autosave: true, as: :engagements, class_name: 'StatusEngagements', inverse_of: :facebook_profile

  has_many :facebook_friendships, foreign_key: :facebook_profile_from_id

  #HEAVY_FIELDS = [:friends, :edges, :graph, :histogram_num_connections]

  #default_scope without(HEAVY_FIELDS)
  #scope :graph_only, unscoped.only(:graph)
  #scope :friends_only, unscoped.only(:friends)


  # 1. Look up by token.
  # 2. If that fails, go to FB and get UID then try to find record by UID.
  # 3. If that fails, too, then we assume we don't have the record yet -> create new.
  def self.find_or_create_by_token(token)
    user = User.where(token: token, provider: 'facebook').first

    if user.nil?
      uid = FacebookProfile.get_uid(token)

      # TODO: Use Mongoid 3.0's find_and_modify here to make the user lookup and update atomic
      user = User.where(uid: uid, provider: 'facebook').first
    end

    if user.nil?
      user = User.new(uid: uid, provider: 'facebook')
      user.token = token
      fb_profile = user.build_facebook_profile(uid: uid)
      user.save
    else
      user.update_attribute(:token, token)
      fb_profile = user.facebook_profile || user.create_facebook_profile(uid: uid)
    end

    fb_profile
  end

  def email
    self.info['email']
  end

  def current_location_name
    self.info['location']['name']
  end

  def token
    @token ||= self.user.try(:token)
  end

  # We're not loading graph nor edges nor friends by default, because they're very
  # large and expensive. So, to query if the graph is present we need to run
  # a DB query, without loading the attribute, though. Mongo is good at this...
  def has_graph?
    graph.present? || self.class.unscoped.where(:_id => self.to_param, :graph.ne => nil).exists?
  end

  def has_edges?
    edges.present? || self.class.unscoped.where(:_id => self.to_param, :edges.ne => nil).exists?
  end


end

