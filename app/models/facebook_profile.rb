class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  attr_reader :koala_client
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
  field :likes,  type: Array
  field :checkins,  type: Array
  field :info,    type: Hash


  index :user_id, unique: true

  HEAVY_FIELDS = [:friends, :edges, :graph, :histogram_num_connections]

  default_scope without(HEAVY_FIELDS)
  scope :graph_only, unscoped.only(:graph)

  embeds_many :labels, inverse_of: :facebook_profile

  before_validation :populate_name_uid_image

  def get_nodes_and_edges
    @koala_client = Koala::Facebook::API.new(user.token)

    self.friends = get_all_friends
    self.photos = get_user_photos
    self.image = get_user_picture
    self.posts = get_user_posts
    self.tagged = get_user_tagged
    self.locations = get_user_locations
    self.statuses = get_user_statuses
    self.checkins = get_user_checkins
    self.likes = get_user_likes
    self.info = get_user_info
    self.name = info["name"]
    self.email = info["email"]

    # FB reports at most 5000 rows per query. Based on the mutual friend counts, we can calculate how many friends
    # we should include in the edges query (next) here to stay below 5000 results
    chunks = chunk_friends_by_mutual_friend_count
    fql_queries = fql_quries_for_mutual_friends(chunks)

    self.edges = run_fql_queries_as_batch(fql_queries)
  end

  # We're not loading graph nor edges nor friends by default, because they're very
  # large and expensive. So, to query if the graph is present we need to run
  # a DB query, without loading the attribute, though. Mongo is good at this...
  def has_graph?
    #graph.present? ||
        self.class.unscoped.where(:_id => self.to_param, :graph.ne => nil).exists?
  end

  def has_edges?
    #edges.present? ||
        self.class.unscoped.where(:_id => self.to_param, :edges.ne => nil).exists?
  end

  private

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

  def get_user_photos
    koala_client.get_connections("me", "photos")
  end

  def get_user_locations
    koala_client.get_connections("me", "locations")
  end

  def get_user_posts
    koala_client.get_connections("me", "posts")
  end

  def get_user_statuses
    koala_client.get_connections("me", "statuses")
  end

  def get_user_tagged
    koala_client.get_connections("me", "tagged")
  end

  def get_user_picture
    koala_client.get_picture("me")
  end

  def get_user_likes
    koala_client.get_connections("me", "likes")
  end

  def get_user_checkins
    koala_client.get_connections("me", "checkins")
  end

  def get_user_info
    koala_client.get_object("me")
  end

  # Returns an array of FQL queries to retrieve the edges (connections between) all the friends
  def fql_quries_for_mutual_friends(chunks)
    fql_queries = chunks.map do |chunk|
      ids = chunk.map { |f| f['uid'].to_s }.join(',')
      # Note: 2nd condition below is required to avoid permissions issue.
      "SELECT uid1,uid2 FROM friend WHERE uid1 IN (#{ids}) AND uid2 IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER BY uid1"
    end
    fql_queries.each { |fql| Rails.logger.info "FQL query: " + fql }
  end

  # Returns an array with combined results of all queries
  def run_fql_queries_as_batch(fql_queries)
    koala_client.batch do |batch_api|
      fql_queries.each do |fql|
        batch_api.fql_query(fql)
      end
    end.flatten
  end

  def populate_name_uid_image
    self.name = user.name
    self.image = user.image
    self.uid = user.uid
  end

end

