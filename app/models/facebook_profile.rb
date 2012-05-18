class FacebookProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :uid, :name, :image

  belongs_to :user

  validates :uid, :user_id, presence: true

  field :uid,               type: String
  field :image,             type: String
  field :name,              type: String
  field :friends,           type: Array
  field :edges,             type: Array
  field :graph,             type: String
  field :photos,            type: Array
  field :email,             type: String
  field :tagged,            type: Array
  field :posts,             type: Array
  field :locations,         type: Array
  field :statuses,          type: Array
  field :likes,             type: Array
  field :checkins,          type: Array
  field :info,              type: Hash
  field :created_at,        type: Date
  field :trust_score,       type: Integer
  field :profile_maturity,  type: Integer

  index :user_id, unique: true
  index :uid, unique: true

  embeds_many :labels, inverse_of: :facebook_profile

  has_one :photo_engagements, autosave: true, as: :engagements, class_name: 'PhotoEngagements', inverse_of: :facebook_profile
  has_one :status_engagements, autosave: true, as: :engagements, class_name: 'StatusEngagements', inverse_of: :facebook_profile


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
    queue_user_likes
    queue_user_checkins
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

  def as_json(opts={})
    h = {}
    if self.respond_to?(:degree)  # scoring was successful
      h[:maturity]                  = self.degree
      h[:graph_regularity_lower]    = self.clustering_coefficient_lower
      h[:graph_regularity_upper]    = self.clustering_coefficient_upper
      h[:graph_regularity_mean]     = self.clustering_coefficient_mean
      h[:graph_regularity_actual]   = self.graph_density
      h[:community_diversity_lower] = self.k_core_lower
      h[:community_diversity_upper] = self.k_core_upper
      h[:community_diversity_mean]  = self.k_core_mean
      h[:community_diversity_actual]= self.k_core
    end
    h
  end

  def compute_photo_engagements
    build_photo_engagements if photo_engagements.nil?
    photo_engagements.compute
  end

  def compute_status_engagements
    build_status_engagements if status_engagements.nil?
    status_engagements.compute
  end


  def compute_created_at
    lid = (self.uid).to_i
    if(lid<100000)
      self.created_at = Date.parse('2004-01-01')
    elsif(lid<100000000)
      self.created_at = Date.parse('2007-01-01')
    elsif (lid <1000000000000)
      self.created_at = Date.parse('2009-06-01')
    else
      self.created_at = interpolate_date(lid)
    end
  #  #self.created_at = f(self.uid)
  #  # notice, there are Rails time helpers like 1.month.ago or 1.day.ago + 1.month.from_now, google it/see docs, etc.
  end

  def interpolate_date(lid)
    time_array=[['2009-9-24', '100000241077339'],
               ['2009-11-22', '100000498112056'],
               ['2009-12-10', '100000525348604'],
               ['2009-12-27', '100000585319862'],
               ['2010-2-18', '100000772928057'],
               ['2010-2-28', '100000790642929'],
               ['2010-10-2', '100001590505220'],
               ['2011-12-21', '100003240296778'],
               ['2012-5-8', '100003811911948'],
               ['2012-5-16', '100003875801329']]

    num_record = time_array.length
    dates=Array.new(num_record)
    lids = Array.new(num_record)
    (0..(num_record-1)).each do |i|
      dates[i] = Date.parse(time_array[i][0])
      lids[i] = time_array[i][1].to_i
    end

    lidmin = 0
    lidmax = 0
    idmin = num_record -1
    idmax = 0
    lids.reverse_each do |k|
      if k<= lid
        lidmin = k
        break
      end
      idmin-=1
    end

    lids.each do |k|
      if k>=lid
        lidmax = k
        break
      end
      idmax+=1
    end

    createDate = 0
    if lidmax == lids[0] # date falls before first date available
      delta = lids[0]-lid
      create_date = dates[0] - ((delta.to_f/(lids[1]-lids[0]).to_f)*(dates[1]-dates[0])).to_i
    elsif lidmin==lids[-1] # date is newer then latest available date point
      delta = lid-lids[-1]
      create_date = dates[-1]+ ((delta.to_f/(lids[-1]-lids[-2]).to_f)*(dates[-1]-dates[-2])).to_i
    elsif lidmin==lidmax  # date falls on a record in our database
      create_date = dates[idmin]
    else    # date is in our range, so we interpolate
      delta = lid-lids[idmin]
      create_date = dates[idmin]+ ((delta.to_f/(lids[idmax]-lids[idmin]).to_f)*(dates[idmax]-dates[idmin])).to_i
    end
    return create_date
  end

  def compute_trust_score
    compute_created_at
    page_age = Date.today - self.created_at
    friend_count = self.class.unscoped.where(:_id=>self.to_param).only("friends").first.friends.count
    self.profile_maturity = (Math.tanh(page_age/300.0)*Math.tanh(friend_count/300.0)*100).to_i()
    puts "page age: "+page_age.to_s+" friends count: "+friend_count.to_s+ " profile maturity: "+self.profile_maturity.to_s
    # access photo engagements scores: self.photo_engagements.co_tags_uniques, etc. see methods in PhotoEngagements
    # self.trust_score = ....
    compute_photo_engagements
    compute_status_engagements

    total_likes = self.photo_engagements.likes_uniques + self.status_engagements.likes_uniques
    total_comments = self.photo_engagements.comments_uniques+self.status_engagements.comments_uniques
    total_co_tags = self.photo_engagements.co_tags_uniques

    score_likes = Math.tanh(total_likes/40.0)*(28.3 +5.0*rand())
    score_comments = Math.tanh(total_comments/20.0)*(28.3 +5.0*rand())
    score_co_tags = Math.tanh(total_co_tags/20.0)*(28.3 +5.0*rand())
    self.trust_score = (score_likes+score_comments+score_co_tags).to_i
    puts "Uniques: "
    puts "like: "+ total_likes.to_s + " score: "+score_likes.to_i.to_s
    puts "comments: "+total_comments.to_s+" score: "+score_comments.to_i.to_s
    puts "cotags: " + total_co_tags.to_s + " score: "+score_co_tags.to_i.to_s
    puts "trust_score: "+ trust_score.to_s

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

  def queue_user_likes
    add_to_fb_batch_query(:likes) { |batch_client| batch_client.get_connections("me", "likes") }
  end

  def queue_user_checkins
    add_to_fb_batch_query(:checkins) { |batch_client| batch_client.get_connections("me", "checkins") }
  end

  def queue_user_tagged
    add_to_fb_batch_query(:tagged) { |batch_client| batch_client.get_connections("me", "tagged") }
  end

  def queue_user_info
    add_to_fb_batch_query(:info) { |batch_client| batch_client.get_object("me") }
  end

  # Returns an array of arrays of friends, chunked such that neither sub-array
  # exceeds a sum of 5000 mutual_friends
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

