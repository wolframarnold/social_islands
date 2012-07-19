module Computations::FacebookProfileComputations

  extend ActiveSupport::Concern

  module ClassMethods

    #############################
    # Guess Join Date from UID  #
    #############################

    def uid2joined_on(uid)

      case uid
        when 0...100_000
          Date.civil(2004,1,1)
        when 100_000...100_000_000
          Date.civil(2007,1,1)
        when 100_000_000...1_000_000_000_000
          Date.civil(2009,6,1)
        when 1_000_000_000_000...100_000_000_000_000
          # FB's lost interval -- they supposedly skipped this
          Rails.logger.tagged('uid2joined_on', "FacebookID=#{uid}") { Rails.logger.info "Found Facebook ID #{uid} in range 1_000_000_000_000...100_000_000_000_000 -- didn't expect this. Please investigate" }
          Date.civil(2009,6,1)
        else
          interpolate_date(uid)
      end
    end

    # Ascending order(!!!) date samples taken from actual timelines
    DATE_UID_SAMPLES = [ [100_000_241_077_339, Date.civil(2009, 9,24)],
                         [100_000_498_112_056, Date.civil(2009,11,22)],
                         [100_000_525_348_604, Date.civil(2009,12,10)],
                         [100_000_585_319_862, Date.civil(2009,12,27)],
                         [100_000_772_928_057, Date.civil(2010, 2,18)],
                         [100_000_790_642_929, Date.civil(2010, 2,28)],
                         [100_001_590_505_220, Date.civil(2010,10, 2)],
                         [100_003_240_296_778, Date.civil(2011,12,21)],
                         [100_003_811_911_948, Date.civil(2012, 5, 8)],
                         [100_003_875_801_329, Date.civil(2012, 5,16)] ]
    UID_SAMPLES  = DATE_UID_SAMPLES.map(&:first)
    DATE_SAMPLES = DATE_UID_SAMPLES.map(&:last)

    def interpolate_date(uid)
      gteq_index = UID_SAMPLES.find_index {|uid_sample| uid <= uid_sample}

      case gteq_index
        when 0   # uid falls before first available sample, use slope of first interval
          DATE_SAMPLES[0] - interpolate_date_offset(0,1, UID_SAMPLES[0] - uid)
        when nil # uid falls after last available sample, use slope of last interval
          DATE_SAMPLES[-1] + interpolate_date_offset(-1, -2, uid - UID_SAMPLES[-1])
        else     # uid is within sample range
          DATE_SAMPLES[gteq_index-1] + interpolate_date_offset(gteq_index-1, gteq_index, uid - UID_SAMPLES[gteq_index-1])
      end
    end

    def interpolate_date_offset(lower, upper, uid_delta)
      ((uid_delta.to_f / (UID_SAMPLES[upper] - UID_SAMPLES[lower])) * (DATE_SAMPLES[upper] - DATE_SAMPLES[lower])).to_i
    end

  end

  ##############################
  # Photo & Status Engagements #
  ##############################

  def compute_engagements
    %w(photos statuses locations tagged).each do |eng_type|
      initial = HashWithIndifferentAccess.new(co_tagged_with: {}, liked_by: {}, commented_by: {}, from: {})

      if send(eng_type).blank?
        # initialize with 0, so that later computations don't fail
        results = initial
      else
        results = send(eng_type).reduce(initial) do |stats, engagement|
          # TODO: Deal with case when the tagged party doesn't have a UID (i.e. is not on FB)
          # See tracker story: https://www.pivotaltracker.com/story/show/29603637
          add_engagements(stats['co_tagged_with'], engagement, 'tags')
          add_engagements(stats['liked_by'], engagement, 'likes')
          add_engagements(stats['commented_by'], engagement, 'comments')
          add_from_engagements(stats['from'], engagement)
          stats
        end
      end
      results['co_tags_uniques']  = results['co_tagged_with'].length
      results['co_tags_total']    = results['co_tagged_with'].sum {|attr, val| val}
      results['likes_uniques']    = results['liked_by'].length
      results['likes_total']      = results['liked_by'].sum {|attr, val| val}
      results['comments_uniques'] = results['commented_by'].length
      results['comments_total']   = results['commented_by'].sum {|attr, val| val}
      results['from_uniques'] = results['from'].length
      results['from_total']   = results['from'].sum {|attr, val| val}
      self.send("#{eng_type.singularize}_engagements=", results)  # assign to photo_engagements, status_engagements
    end
  end

  # adds uid => count hash entries
  def add_from_engagements(result, raw_data_hash)
    return if raw_data_hash['from'].nil? || raw_data_hash['from']['id'].nil?
    from_uid=raw_data_hash['from']['id'].to_s
    return if from_uid == self.uid.to_s
    result[from_uid] ||= 0
    result[from_uid] += 1
  end

  #works for likes, comments, tags, need a seperate function for from
  def add_engagements(result, raw_data_hash, engagement_name)
    return if raw_data_hash[engagement_name].nil?
    return if raw_data_hash[engagement_name]['data'].nil?  #if there is a 0 entry, data fields does not exist, instead, a count=0
    raw_data_hash[engagement_name]['data'].each do |eng|
      # Comments has an additional sub-hash "from"
      friend_uid = engagement_name == 'comments' ? eng['from']['id'].to_s : eng['id'].to_s
      next if friend_uid.nil?  # TODO: record this case (name only, no ID -- non-FB member)
                               # see story: https://www.pivotaltracker.com/story/show/29603637
      next if friend_uid == self.uid.to_s # skip self-comments, they don't count as engagement
      # We're storing UID's as strings here, because BSON/Mongo cannot handle integers as keys
      result[friend_uid] ||= 0
      result[friend_uid] += 1
    end
  end
  private :add_engagements

  ##############################
  #    Top friends             #
  ##############################
  def hash_merge(h1, w_h1, h2, w_h2)
    new_hash=Hash.new(0)
    h1.each {|key, val| new_hash[key]+=val*w_h1}
    h2.each {|key, val| new_hash[key]+=val*w_h2}
    return new_hash
  end

  def compute_top_friends
    w_photo_like = 1
    w_photo_comment = 1
    w_photo_cotag = 1
    w_photo_from = 3

    w_status_like = 2
    w_status_comment = 4

    w_location_cotag = 2
    w_location_from = 4

    w_tagged_like = 1
    w_tagged_comment = 2
    w_tagged_from = 4

    compute_engagements

    co_tag=hash_merge(photo_engagements['co_tagged_with'], w_photo_cotag, location_engagements['co_tagged_with'], w_location_cotag)

    from=hash_merge(photo_engagements['from'], w_photo_from, location_engagements['from'], w_location_from)
    from=hash_merge(from, 1, tagged_engagements['from'], w_tagged_from)

    liked_by=hash_merge(photo_engagements['liked_by'], w_photo_like, status_engagements['liked_by'], w_status_like)
    liked_by=hash_merge(liked_by, 1, tagged_engagements['liked_by'], w_tagged_like)

    commented_by=hash_merge(photo_engagements['commented_by'], w_photo_comment, status_engagements['commented_by'], w_status_comment)
    commented_by=hash_merge(commented_by, 1, tagged_engagements['commented_by'], w_tagged_comment)

    in_bound=hash_merge(co_tag, 1, from, 1)
    in_bound=hash_merge(in_bound, 1, liked_by, 1)
    in_bound=hash_merge(in_bound, 1, commented_by, 1)
    in_bound.delete("")
    in_bound=in_bound.sort_by{|key, val| -val}

    #in_bound[0..19].each do |key, val|
    #  name=FacebookProfile.where(uid:key).blank? ? " " : FacebookProfile.where(uid:key).first['name']
    #  puts name+" "+ val.to_s + " " + key
    #end

    in_bound[0..19]   # [ [UID1, Score1], [UID2, Score2] ]
  end



  ##############################
  #    Profile Completeness    #
  ##############################

  COMPLETENESS_FACTORS = %w(education work political location hometown gender email website birthday bio relationship_status about quotes religion verified)

  def compute_profile_completeness
    completeness = 0
    if self.about_me.present?
      completeness = COMPLETENESS_FACTORS.count do |attr|
        # special casing 'verified' because it is a boolean true or false, not a string!
        attr == 'verified' ? self.about_me['verified'] : self.about_me[attr].present?
      end
    end

    self.profile_completeness = completeness
  end

  ##############################
  #    Profile Authenticity    #
  ##############################

  def compute_profile_authenticity
    self.joined_on = FacebookProfile.uid2joined_on(self.uid)
    page_age = Date.today - self.joined_on
    friend_count = self.facebook_profile_uids.count

    self.profile_authenticity = ( Math.tanh(page_age/300.0) * Math.tanh(friend_count/300.0) * 80 +
                                  compute_profile_completeness * 20.0 / COMPLETENESS_FACTORS.length ).round
  end

  #################
  #  Trust Score  #
  #################

  def compute_trust_score
    compute_engagements

    total_likes    = self.photo_engagements['likes_uniques']    + self.status_engagements['likes_uniques']
    total_comments = self.photo_engagements['comments_uniques'] + self.status_engagements['comments_uniques']
    total_co_tags  = self.photo_engagements['co_tags_uniques']  + self.status_engagements['co_tags_uniques']

    # TODO: Find out that the community average normalization factors are here, here we use 40,20,20
    raw_score_likes    = Math.tanh( total_likes    / 40.0)
    raw_score_comments = Math.tanh( total_comments / 20.0)
    raw_score_co_tags  = Math.tanh( total_co_tags  / 20.0)

    # Weights:
    # We weight photos highest, then comments, then likes, in descending order of effort required to generate
    # We also introduce a random factor into the weight percentages to prevent gaming
    # Base: 40% photo tags, 35% comments, 25% likes

    weight_photos   = 40.0 - 2.5 + 5.0 * rand
    weight_comments = 35.0 - 2.5 + 5.0 * rand
    weight_likes    = 100.0 - weight_photos - weight_comments

    #p "weight_photos = #{weight_photos.inspect}"
    #p "weight_comments = #{weight_comments.inspect}"
    #p "weight_likes = #{weight_likes.inspect}"

    self.trust_score = (raw_score_co_tags * weight_photos + raw_score_comments * weight_comments + raw_score_likes * weight_likes).round
  end

  def compute_all_scores!
    compute_profile_authenticity
    compute_trust_score
    save!
  end

  #def collect_friends_location_stats
  #  friends = FacebookProfile.unscoped.friends_only.find(self.id).friends
  #
  #  num_friends=friends.count
  #
  #  location_hash = Hash.new()
  #
  #  friends.each do |friend|
  #    location = ""
  #    if not(friend["current_location"].nil?)
  #      fb_location = friend["current_location"]
  #      country = fb_location["country"] || ""
  #      if country == "United States"
  #        name = fb_location["name"] || ""
  #        if name.blank?
  #          city = fb_location["city"] || ""
  #          state = fb_location["state"] || ""
  #          location = city+", " + state + ", " + country
  #        else
  #          location = name + ", " + country
  #        end
  #      else # foreign country
  #        name = fb_location["name"] || ""
  #        if name.length==0
  #          city = fb_location["city"] || ""
  #          state = fb_location["state"] || ""
  #          location = city+", " + state + ", " + country
  #        else
  #          location = name
  #        end
  #      end
  #      #puts fb_location;
  #      #puts location;
  #    end
  #
  #    if location.present?
  #      if location_hash[location].nil?
  #        location_hash[location]=1
  #      else
  #        location_hash[location] = location_hash[location]+1
  #      end
  #    end
  #  end
  #
  #  location_hash.sort_by {|name, count| count}.reverse
  #end
  #
  #def geolocation_coordiates_for_friends_locations(location_hash)
  #  coordinate_hash = Hash.new()
  #  num_location = location_hash.length
  #
  #  num_loc = num_location > 5 ? 4 : numlocation
  #  (0..num_loc).each do |i|
  #    location = location_hash[i][0]
  #    coordinate_hash[location] = Geocoder.coordinates(location)
  #    if i>0
  #      cord0 = coordinate_hash[location_hash[0][0]]
  #      cord1 = coordinate_hash[location_hash[i][0]]
  #      puts Geocoder::Calculations.distance_between(cord0, cord1)
  #    end
  #  end
  #end

end