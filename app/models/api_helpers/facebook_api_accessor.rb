module ApiHelpers::FacebookApiAccessor

  extend ActiveSupport::Concern

  included do

    field :uid,               type: String
    field :image,             type: String
    field :name,              type: String
    # TODO: move 'graph' elsewhere
    field :graph,             type: String
    field :photos,            type: Array
    field :tagged,            type: Array
    field :posts,             type: Array
    field :locations,         type: Array
    field :statuses,          type: Array
    field :likes,             type: Array
    field :checkins,          type: Array
    field :info,              type: Hash
    field :permissions,       type: Hash
    field :joined_on,         type: Date

    # TODO: Move the computed values to the User model
    field :trust_score,       type: Integer
    field :profile_maturity,  type: Integer

    field :user_stat,         type: Hash
    field :info_via_friend,   type: Hash

    index :user_id, unique: true
    index :uid, unique: true

  end

  # Profile info on a user
  FB_FIELDS_USER = %(
  )

  # Profile info on a friend
  # Taken from https://developers.facebook.com/docs/reference/fql/user/
  FB_FIELDS_FRIENDS = %w(
    uid
    name first_name last_name
    pic pic_square pic_big
    affiliations
    timezone
    religion
    birthday birthday_date
    devices
    hometown_location current_location
    sex relationship_status significant_other_id
    political
    interests
    music tv movies books quotes about_me
    notes_count wall_count
    status
    locale
    profile_url
    pic_cover
    verified
    profile_blurb
    family
    website
    email
    name_format
    work
    education
    inspirational_people
    languages
    likes_count
    friend_count
    mutual_friend_count
    can_post
  )

  # About the friendship, holds both ways
  FB_FIELDS_FRIENDSHIP_UNDIRECTED = %w(
    mutual_friend_count
  )

  # About the friendship, holds only one way
  FB_FIELDS_FRIENDSHIP_DIRECTED = %w(
    can_post
  )

  module ClassMethods

    def get_uid(token)
      fields = Koala::Facebook::API.new(token).get_object('me', fields: 'id')
      fields['id']
    end

  end

  # Instance Methods

  def get_about_me_and_friends(friend_uids = nil)
    queue_user_info
    queue_all_friends(friend_uids)

    execute_fb_batch_query

    self.uid = self.info['id']
    self.name = self.info['name']
  end

  def get_engagement_data_and_network_graph
    queue_user_permissions
    queue_user_photos
    queue_user_picture
    queue_user_posts
    queue_user_tagged
    queue_user_locations
    queue_user_statuses
    queue_user_likes
    queue_user_checkins
    queue_fql_queries_for_mutual_friends

    execute_fb_batch_query
  end

  def import_profile_and_network!
    get_about_me_and_friends
    get_engagement_data_and_network_graph
    save!  # if this is going to SQL, put save! last to take advantage of transaction
    generate_friends_records!
  end

  private

  def queue_user_permissions
    add_to_fb_batch_query(:permissions) { |batch_client| batch_client.get_connections("me", "permissions") }
  end

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
    add_to_fb_batch_query(:about_me) { |batch_client| batch_client.get_object("me") }
  end

  # Returns array of hashes of all the friends
  def queue_all_friends(friend_uids = nil)
    if friend_uids.nil?
      fql = "SELECT #{FB_FIELDS_FRIENDS.join(',')} FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER by mutual_friend_count DESC"
    else
      friend_uids = Array.wrap(friend_uids)
      fql = "SELECT #{FB_FIELDS_FRIENDS.join(',')} FROM user WHERE uid IN (#{friend_uids.join(',')}) ORDER by mutual_friend_count DESC"
    end

    add_to_fb_batch_query(:friends) { |batch_client| batch_client.fql_query(fql) }
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

  # Returns an array of FQL queries to retrieve the edges (connections between) all the friends
  def queue_fql_queries_for_mutual_friends
    # FB reports at most 5000 rows per query. Based on the mutual friend counts, we can calculate how many friends
    # we should include in the edges query (next) here to stay below 5000 results
    chunks = chunk_friends_by_mutual_friend_count

    fql_queries = chunks.map do |chunk|
      ids = chunk.map { |f| f['uid'].to_s }.join(',')
      # Note: 2nd condition below is required to avoid permissions issue.
      "SELECT uid1,uid2 FROM friend WHERE uid1 IN (#{ids}) AND uid2 IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER BY uid1"
    end
    fql_queries.each do |fql|
      add_to_fb_batch_query(:edges, true) { |batch_client| batch_client.fql_query(fql) }
    end
  end

  def add_to_fb_batch_query(attr, chunked=false)
    @batch_client ||= Koala::Facebook::GraphBatchAPI.new(koala_client.access_token, koala_client)
    @batched_attributes ||= []
    @batched_attributes << {attr: attr, chunked: chunked}
    yield @batch_client
  end

  def execute_fb_batch_query
    # Batch execution returns an array of combined results, in the order they were queued
    Rails.logger.tagged("User#_id=#{self.user_id}") { Rails.logger.info "FB Batch call for attrs: [#{@batched_attributes.join(', ')}]" }
    @batch_client.execute.each_with_index do |result, idx|
      attr = @batched_attributes[idx]
      if attr[:chunked]
        self.send("#{attr[:attr]}=", []) if self.send(attr[:attr]).nil?
        self.send(attr[:attr]).concat(result)
      else
        self.send "#{attr[:attr]}=", result
      end
    end
    # reset batch client and array, for next batch
    @batch_client = @batched_attributes = nil
  end

  def koala_client
    @koala_client ||= Koala::Facebook::API.new(self.token)
  end

  def generate_friends_records!
    friends.each do |friend|
      user, fp = User.find_or_create_with_facebook_profile_by_uid(uid: friend['uid'], name: friend['name'], image: friend['pic'])
      fp.update_attribute(:info_via_friend, friend)
      create_or_update_friendships(fp, friend)
    end
  end

  def create_or_update_friendships(friend_fp, friend_raw)
    outbound_friendship_ids = {facebook_profile_from_id: self.id, facebook_profile_to_id: friend_fp.id}
    outbound_friendship_params = outbound_friendship_ids.merge friend_raw.slice *(FB_FIELDS_FRIENDSHIP_DIRECTED + FB_FIELDS_FRIENDSHIP_UNDIRECTED)
    FacebookFriendship.collection.update(outbound_friendship_ids, {:$set => outbound_friendship_params}, upsert: true)

    inbound_friendship_ids = {facebook_profile_from_id: friend_fp.id, facebook_profile_to_id: self.id}
    inbound_friendship_params = inbound_friendship_ids.merge friend_raw.slice(*FB_FIELDS_FRIENDSHIP_UNDIRECTED)
    FacebookFriendship.collection.update(inbound_friendship_ids, {:$set => inbound_friendship_params}, upsert: true)
  end

end