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

  index :user_id, unique: true
  index :uid, unique: true

  HEAVY_FIELDS = [:friends, :edges, :graph, :histogram_num_connections]

  default_scope without(HEAVY_FIELDS)
  scope :graph_only, unscoped.only(:graph)

  embeds_many :labels, inverse_of: :facebook_profile

  before_validation :populate_name_uid_image

  def get_nodes_and_edges
    @koala_client = Koala::Facebook::API.new(user.token)

    self.friends = get_all_friends

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
    graph.present? || self.class.unscoped.where(:_id => self.to_param, :graph.ne => nil, :graph.ne => '').exists?
  end

  def has_edges?
    edges.present? || self.class.unscoped.where(:_id => self.to_param, :edges.ne => nil, :graph.ne => '').exists?
  end

  def as_json(opts={})
    h = {}
    h[:maturity]                  = self.degree
    h[:graph_regularity_lower]    = self.clustering_coefficient_lower
    h[:graph_regularity_upper]    = self.clustering_coefficient_upper
    h[:graph_regularity_mean]     = self.clustering_coefficient_mean
    h[:graph_regularity_actual]   = self.graph_density
    h[:community_diversity_lower] = self.k_core_lower
    h[:community_diversity_upper] = self.k_core_upper
    h[:community_diversity_mean]  = self.k_core_mean
    h[:community_diversity_actual]= self.k_core
    h
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
    chunks
  end

  # Returns array of hashes of all the friends
  def get_all_friends
    friends = koala_client.fql_query('SELECT uid,name,first_name,last_name,pic,pic_square,sex,verified,likes_count,mutual_friend_count FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER by mutual_friend_count DESC')
    Rails.logger.tagged("User#_id=#{self.uid}") { Rails.logger.info "#{friends.length} friends" }
    friends
  end

  # Returns an array of FQL queries to retrieve the edges (connections between) all the friends
  def fql_quries_for_mutual_friends(chunks)
    chunks.map do |chunk|
      ids = chunk.map { |f| f['uid'].to_s }.join(',')
      # Note: 2nd condition below is required to avoid permissions issue.
      "SELECT uid1,uid2 FROM friend WHERE uid1 IN (#{ids}) AND uid2 IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER BY uid1"
    end
  end

  # Returns an array with combined results of all queries
  def run_fql_queries_as_batch(fql_queries)
    edges = koala_client.batch do |batch_api|
      fql_queries.each do |fql|
        batch_api.fql_query(fql)
      end
    end.flatten
    Rails.logger.tagged("User#_id=#{self.uid}") { Rails.logger.info "#{edges.length} edges" }
    edges
  end

  def populate_name_uid_image
    self.name = user.name
    self.image = user.image
    self.uid = user.uid
  end

end

