class FacebookProfile

  include MongoMapper::Document

  attr_reader :koala_client, :friends, :edges

  belongs_to :user

  key :friends, Array
  key :edges,   Array
  many :labels
  key :graph,   String
  timestamps!

  def get_nodes_and_edges
    @koala_client = Koala::Facebook::API.new(user.token)

    self.friends = get_all_friends

    # FB reports at most 5000 rows per query. Based on the mutual friend counts, we can calculate how many friends
    # we should include in the edges query (next) here to stay below 5000 results
    chunks = chunk_friends_by_mutual_friend_count
    fql_queries = fql_quries_for_mutual_friends(chunks)

    self.edges = run_fql_queries_as_batch(fql_queries)
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

end

