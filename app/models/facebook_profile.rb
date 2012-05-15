class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :uid, :name, :image

  belongs_to :user

  validates :uid, :user_id, presence: true

  field :uid,     type: String
  field :image,   type: String
  field :name,    type: String
  field :friends, type: Array
  field :edges,   type: Array
  field :graph,   type: String
  field :photos,  type: Array
  field :email,   type: String
  field :tagged,  type: Array
  field :posts,   type: Array
  field :locations, type: Array
  field :statuses,  type: Array
  field :info,    type: Hash

  index :user_id, unique: true

  embeds_many :labels, inverse_of: :facebook_profile

  has_one :photo_engagements, autosave: true, as: :engagements, class_name: 'PhotoEngagements', inverse_of: :facebook_profile

  HEAVY_FIELDS = [:friends, :edges, :graph, :histogram_num_connections]

  default_scope without(HEAVY_FIELDS)
  scope :graph_only, unscoped.only(:graph)

  before_validation :populate_name_uid_image

  def get_profile_and_network_graph!
    self.friends = get_all_friends
    queue_user_photos
    queue_user_picture
    queue_user_posts
    queue_user_tagged
    queue_user_locations
    queue_user_statuses
    queue_user_info
    queue_fql_quries_for_mutual_friends

    execute_fb_batch_query

    self.name = self.info["name"]
    self.email = self.info["email"]

    save!
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

  def compute_photo_engagements
    build_photo_engagements if photo_engagements.nil?
    photo_engagements.compute
  end

  private

  def queue_user_photos
    add_to_fb_batch_query(:photos) { |batch_client| batch_client.get_connections("me", "photos") }
  end

  def queue_user_picture
    add_to_fb_batch_query(:image) { |batch_client| batch_client.get_picture("me") }
  end

  def queue_user_locations
    add_to_fb_batch_query(:locations) { |batch_client| batch_client.get_connections("me", "locations") }
  end

  def queue_user_posts
    add_to_fb_batch_query(:posts) { |batch_client| batch_client.get_connections("me", "posts") }
  end

  def queue_user_statuses
    add_to_fb_batch_query(:statuses) { |batch_client| batch_client.get_connections("me", "statuses") }
  end

  # FIXME: Is this working? Don't see this documented in FB
  def queue_user_tagged
    add_to_fb_batch_query(:tagged) { |batch_client| batch_client.get_connections("me", "tagged") }
  end

  def queue_user_info
    add_to_fb_batch_query(:info) { |batch_client| batch_client.get_object("me") }
  end

  # Returns an array of arrays of friends, chunked such that neither sub-array
  # exeeds a sum of 5000 mutual_friends
  def chunk_friends_by_mutual_friend_count
    row_ct = 0
    chunks = []
    curr_chunk = []
    friends.each do |friend|
      mf_ct = (friend['mutual_friend_count'] || 5) # sometimes mutual_friend_count returns nil, FB bug? https://developers.facebook.com/bugs/249611311795121  Assume 5 mutual friends
      row_ct += mf_ct
      if row_ct >= 5000
        chunks << curr_chunk
        curr_chunk = []
        row_ct = mf_ct
      end
      curr_chunk << friend
    end
    chunks << curr_chunk
    Rails.logger.info "Friend chunks: #{chunks.length}: " + chunks.map{|ch| ch.map{|f| f.slice('uid','mutual_friend_count')}}.inspect
    chunks
  end

  # Returns array of hashes of all the friends
  def get_all_friends
    koala_client.fql_query('SELECT uid,name,first_name,last_name,pic,pic_square,sex,verified,likes_count,mutual_friend_count FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER by mutual_friend_count DESC')
  end

  #
  #fql_queries = queue_fql_quries_for_mutual_friends(chunks)
  #
  #self.edges = run_fql_queries_as_batch(fql_queries)


  # Returns an array of FQL queries to retrieve the edges (connections between) all the friends
  def queue_fql_quries_for_mutual_friends
    # FB reports at most 5000 rows per query. Based on the mutual friend counts, we can calculate how many friends
    # we should include in the edges query (next) here to stay below 5000 results
    chunks = chunk_friends_by_mutual_friend_count

    fql_queries = chunks.map do |chunk|
      ids = chunk.map { |f| f['uid'].to_s }.join(',')
      # Note: 2nd condition below is required to avoid permissions issue.
      "SELECT uid1,uid2 FROM friend WHERE uid1 IN (#{ids}) AND uid2 IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER BY uid1"
    end
    #fql_queries.each { |fql| Rails.logger.info "FQL query: " + fql }
    fql_queries.each do |fql|
      add_to_fb_batch_query(:edges, true) { |batch_client| batch_client.fql_query(fql) }
    end
  end

  def populate_name_uid_image
    self.name = user.name
    self.image = user.image
    self.uid = user.uid
  end

  def add_to_fb_batch_query(attr, chunked=false)
    @batch_client ||= Koala::Facebook::GraphBatchAPI.new(koala_client.access_token, koala_client)
    @batched_attributes ||= []
    @batched_attributes << {attr: attr, chunked: chunked}
    yield @batch_client
  end

  def execute_fb_batch_query
    # Batch execution returns an array of combined results, in the order they were queued
    @batch_client.execute.each_with_index do |result, idx|
      attr = @batched_attributes[idx]
      if attr[:chunked]
        self.send("#{attr[:attr]}=", []) if self.send(attr[:attr]).nil?
        self.send(attr[:attr]).concat(result)
      else
        self.send "#{attr[:attr]}=", result
      end
    end
  end

  def koala_client
    @koala_client ||= Koala::Facebook::API.new(user.token)
  end

end

