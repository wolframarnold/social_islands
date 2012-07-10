module ApiHelpers::FacebookApiAccessor

  extend ActiveSupport::Concern

  included do

    attr_accessor :friends_raw, :mutual_friends_raw

  end

  # Note: We're not using has_and_belongs_to_many, because Mongoid's implementation
  # of this wants to save both records after adding a reference on either side
  # which does not scale well. Since we only write the relationships once and all other
  # access is to read, the Mongoid has_and_belongs_to_many relationship doesn't add that
  # much for us anyway; we simply implement the read accessor here
  def facebook_profiles
    FacebookProfile.any_in(uid: facebook_profile_uids)
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

    def get_facebook_id_name_image(token)
      fields = Koala::Facebook::API.new(token).get_object('me', fields: 'id,name,picture')
      # NOTE: FB also returns a "type" field which is, e.g "user" but probably indicates 'page' or similar for other entities
      fields['image'] = fields['picture']
      fields['facebook_id'] = fields['id']
      fields.slice *%w(facebook_id name image)
    end

  end

  # Instance Methods

  def import_profile_and_network!(only_uids=nil)
    get_about_me_and_friends(only_uids)
    get_engagement_data_and_network_graph
    self.last_fetched_at = Time.now.utc
    self.last_fetched_by = self.uid
    generate_friends_records!  # will save
  end

  def koala_client
    @koala_client ||= Koala::Facebook::API.new(self.token)
  end

  def get_about_me_and_friends(only_uids = nil)
    queue_user_about_me
    queue_all_friends(only_uids)

    execute_fb_batch_query

    self.uid = self.about_me['id']
    self.name = self.about_me['name']
  end

  def generate_friends_records!
    mutual_friends_ids = gather_friends_by_uid_from_raw_data
    self.edge_count = 0
    friends_raw.each do |friend_raw|
      fp = self.class.update_or_create_by_facebook_id_and_api_key friend_raw.merge({token: token, api_key: api_key})
      fp.map_friend_to_ego_attributes(friend_raw)
      fp.facebook_profile_uids = mutual_friends_ids[fp.uid].to_a + [self.uid]
      fp.last_fetched_at = Time.now
      fp.last_fetched_by = self.uid
      fp.save!
      self.can_post << fp.uid if friend_raw['can_post']
      self.facebook_profile_uids << fp.uid
      self.edge_count += fp.facebook_profile_uids.length
    end
    save!
  end

  # (Partial) mapping of the FB-returned attributes of a friend
  # into the record of a direct user (ego) -- this is to normalize access
  def map_friend_to_ego_attributes(friend_raw)
    self.fields_via_friend = friend_raw
    self.name = friend_raw['name']
    self.image = friend_raw['pic']
  end

  private

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

  # Converts edged from FB raw data, like [{'123' => '456'}, {'123' => '457'}, ...]
  # into a hash where each key is a (numerical) UID and each value is a list of friend UID's, e.g.:
  # {123 => [456, 789], 456 => [123, 789], ...}
  def gather_friends_by_uid_from_raw_data
    mutual_friends_raw.reduce({}) do |hash, uid_pair|  # uid_pair: {'123' => '456'}
      uid1, uid2 = uid_pair.values.map(&:to_i)
      hash[uid1] ||= Set.new
      hash[uid1] << uid2
      hash[uid2] ||= Set.new
      hash[uid2] << uid1
      hash
    end
  end

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

  def queue_user_about_me
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

    add_to_fb_batch_query(:friends_raw) { |batch_client| batch_client.fql_query(fql) }
  end

  # Returns an array of arrays of friends, chunked such that neither sub-array
  # exceeds a sum of 5000 mutual_friends
  def chunk_friends_by_mutual_friend_count
    row_ct = 0
    chunks = []
    curr_chunk = []
    friends_raw.each do |friend|
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

  # Returns an array of FQL queries to retrieve the egdes (connections between) all the friends
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
      add_to_fb_batch_query(:mutual_friends_raw, true) { |batch_client| batch_client.fql_query(fql) }
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
    Rails.logger.tagged("FacebookProfile#_id=#{self.to_param}") { Rails.logger.info "FB Batch call for attrs: [#{@batched_attributes.join(', ')}]" }
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

end