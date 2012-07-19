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

  # Profile fields from /me or /<uid> Graph API, for direct (ego) user as well as friends
  # This is similar but not exactly identical to what we can get from an FQL Query
  # It seems that we still need FQL to get things like likes_count, friend_count, wall_count
  FB_USER_PROFILE_FIELDS = %w(
    name
    first_name
    last_name
    gender
    locale
    languages
    link
    username
    timezone
    verified
    bio
    birthday
    cover
    devices
    education
    email
    hometown
    location
    political
    picture
    religion
    significant_other
    website
    work
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
    self.facebook_api_error = nil  # clear errors before making fb calls

    execute_as_batch_query do
      get_about_me_and_friends(only_uids)
    end

    execute_as_batch_query do
      # get_friends_details  # see comments at method definition -- this causes too many queries for now
      get_engagement_data_and_network_graph
    end

    create_friends_records_and_save_stats! # will save
  end

  def koala_client
    @koala_client ||= Koala::Facebook::API.new(self.token)
  end

  def create_friends_records_and_save_stats!
    mutual_friends_ids = gather_friends_by_uid_from_raw_data
    self.edge_count = 0
    friends_raw.each do |friend_raw|
      fp = self.class.update_or_create_by_facebook_id_and_app_id friend_raw.merge(app_id: app_id)
      fp.friend_raw_to_attributes(friend_raw)
      fp.facebook_profile_uids = mutual_friends_ids[fp.uid].to_a + [self.uid]
      fp.last_fetched_at = Time.now
      fp.last_fetched_by = self.uid
      fp.save!
      self.facebook_profile_uids << fp.uid
      self.edge_count += fp.facebook_profile_uids.length
    end
    Rails.logger.info "Created #{friends_raw.length} records for friends"

    set_audit_flags
    save!
  end

  def set_audit_flags
    self.last_fetched_at = Time.now.utc
    self.last_fetched_by = self.uid
    self.fetched_directly = true
  end

  # (Partial) mapping of the FB-returned attributes of a friend
  # into the record of a direct user (ego) -- this is to normalize access
  def friend_raw_to_attributes(friend_raw)
    self.image = friend_raw['pic'].present? ? friend_raw['pic'] : friend_raw['picture']
    friend_raw.except('uid', 'pic', 'picture', 'mutual_friend_count').each do |key, val|
      self.send("#{key}=", val) if val.present?
    end
  end

  private

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

  def get_about_me_and_friends(only_uids)
    queue_about_me('me') do |res|
      self.about_me = res
      self.uid      = res['id']
      self.name     = res['name']
      self.image    = res['picture']
    end
    queue_friends(only_uids) do |res|
      self.friends_raw = res
    end
  end

  # Note: This method kicks off 9 queries for every friend.
  # Somebody with 2000 friends would produce 18,000 queries!
  # Each batch can only hold 50 queries, so that still leaves 360 queries -- too many for now.
  # We can do this maybe on a throttled background job and fill in over time -- later.
  def get_friends_details
    friends_raw.each do |friend|
      queue_about_me(friend['uid'])       { |res| friend['about_me']  = res }
      queue_connection('me', 'photos')    { |res| friend['photos']    = res }
      queue_connection('me', 'posts')     { |res| friend['posts']     = res }
      queue_connection('me', 'tagged')    { |res| friend['tagged']    = res }
      queue_connection('me', 'locations') { |res| friend['locations'] = res }
      queue_connection('me', 'statuses')  { |res| friend['statuses']  = res }
      queue_connection('me', 'likes')     { |res| friend['likes']     = res }
      queue_connection('me', 'feed')      { |res| friend['feed']      = res }
    end
  end

  def get_engagement_data_and_network_graph
    queue_connection('me', 'permissions') { |res| self.permissions = res }
    queue_connection('me', 'photos')      { |res| self.photos      = res }
    queue_connection('me', 'posts')       { |res| self.posts       = res }
    queue_connection('me', 'tagged')      { |res| self.tagged      = res }
    queue_connection('me', 'locations')   { |res| self.locations   = res }
    queue_connection('me', 'statuses')    { |res| self.statuses    = res }
    queue_connection('me', 'likes')       { |res| self.likes       = res }
    queue_connection('me', 'checkins')    { |res| self.checkins    = res }
    queue_connection('me', 'feed')        { |res| self.feed        = res }
    self.mutual_friends_raw = []
    queue_fql_queries_for_mutual_friends  { |res| self.mutual_friends_raw.concat(res) }
  end

  # user is "me" or a UID
  # connection_name is one of the valid FB connection names, e.g. photos, permissions, feed, etc.
  # which will be saved to a database field by the same name
  def queue_connection(user, connection_name, &block)
    # Koala does not pass on the block in batch mode (https://github.com/arsduo/koala/issues/237)...
    #batch_client.get_connections user, connection_name, &block
    # So we have to use the lower-level API
    batch_client.graph_call_in_batch("#{user}/#{connection_name}", {}, 'get', {}, &block)
  end

  # user is "me" or a UID
  def queue_about_me(user, &block)
    # batch_client.get_object user, {fields: FB_USER_PROFILE_FIELDS.join(',')}, {}, &block
    # Koala issue workaround: https://github.com/arsduo/koala/issues/237
    batch_client.graph_call_in_batch(user.to_s, {fields: FB_USER_PROFILE_FIELDS.join(',')}, 'get', {}, &block)
  end

  # Returns array of hashes of all the friends
  def queue_friends(friend_uids, &block)
    if friend_uids.nil?
      fql = 'SELECT uid,name,pic,mutual_friend_count FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1=me())'
    else
      fql = "SELECT uid,name,pic,mutual_friend_count FROM user WHERE uid IN (#{friend_uids.join(',')})"
    end
    # batch_client.fql_query fql, &block
    # Koala issue workaround: https://github.com/arsduo/koala/issues/237
    batch_client.graph_call_in_batch('fql', {q: fql}, 'get', {}, &block)
  end

  # Returns an groups of friends ids chunked such that neither sub-array
  # exceeds a sum of 5000 mutual_friends
  def chunk_friends_by_mutual_friend_count
    row_ct = 0
    friends_raw.slice_before do |friend|
      mut_fr_ct = friend['mutual_friend_count'] || 5 # sometimes mutual_friend_count returns nil, FB bug? https://developers.facebook.com/bugs/249611311795121  Assume 5 mutual friends
      row_ct += mut_fr_ct
      row_ct > 5000 && row_ct = 0  # return true and set row_ct to 0 (which also evaluates to true) if > 5000
    end.map do |friends_chunk|  # friends_chunk is a sub-array of friend_raw records, chunked according to the 5000 mutual friends rule
      friends_chunk.map { |friend| friend['uid'] }.join(',')
    end
  end

  # Returns an array of FQL queries to retrieve the egdes (connections between) all the friends
  def queue_fql_queries_for_mutual_friends(&block)
    # FB reports at most 5000 rows per query. Based on the mutual friend counts, we can calculate how many friends
    # we should include in the edges query (next) here to stay below 5000 results

    chunk_friends_by_mutual_friend_count.each do |ids|
      # Note: 2nd condition below is required to avoid permissions issue.
      fql = "SELECT uid1,uid2 FROM friend WHERE uid1 IN (#{ids}) AND uid2 IN (SELECT uid2 FROM friend WHERE uid1=me()) ORDER BY uid1"
      # batch_client.fql_query fql, &block
      # Koala issue workaround: https://github.com/arsduo/koala/issues/237
      batch_client.graph_call_in_batch('fql', {q: fql}, 'get', {}, &block)
    end
  end

  def batch_client
    if @batches.empty? || @batches.last.batch_calls.length == 50
      @batches << Koala::Facebook::GraphBatchAPI.new(koala_client.access_token, koala_client)
    end
    @batches.last
  end

  def execute_as_batch_query
    @batches = []  # clear out queues

    yield              # queue up API calls to batch

    # Facebook doesn't accept more than 50 requests per batch
    # If we get all friend details (in get_friends_details), then
    # we may have up to 400 requests for 2k friends (~ 10 per friend, plus a few more).
    # This doesn't scale, and so we're not doing it at the moment.
    # We still have a mechanism to batch >50 requests.
    # These could also be spawned on multiple threads
    # or (better) the use a parallel HTTP adapter like Typhoeus

    Rails.logger.info "FB Batch Query in progress ... "
    @batches.each_with_index do |batch_client, i|
      Rails.logger.tagged "Batch ##{i}" do
        batch_client.batch_calls.each do |bc|
          Rails.logger.info "FB Call Params: " + bc.to_batch_params(koala_client.access_token).inspect
        end
      end

      batch_client.execute(timeout: 30)  # This will call all the blocks on the queries
    end

  end

end