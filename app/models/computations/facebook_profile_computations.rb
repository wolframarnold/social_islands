module Computations::FacebookProfileComputations

  extend ActiveSupport::Concern

  module ClassMethods

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

    # original code (just method renamed)
    #def uid2joined_on(uid)
    #  if(uid<100_000)
    #    Date.civil(2004,1,1)
    #  elsif(uid<100_000_000)
    #    Date.civil(2007,1,1)
    #  elsif (uid <1_000_000_000_000)
    #    Date.civil(2009,6,1)
    #  else
    #    interpolate_date(uid)
    #  end
    #  #  #self.joined_on = f(self.uid)
    #  #  # notice, there are Rails time helpers like 1.month.ago or 1.day.ago + 1.month.from_now, google it/see docs, etc.
    #end
    #
    #def interpolate_date(lid)
    #  time_array=[['2009-9-24',  '100000241077339'],
    #              ['2009-11-22', '100000498112056'],
    #              ['2009-12-10', '100000525348604'],
    #              ['2009-12-27', '100000585319862'],
    #              ['2010-2-18',  '100000772928057'],
    #              ['2010-2-28',  '100000790642929'],
    #              ['2010-10-2',  '100001590505220'],
    #              ['2011-12-21', '100003240296778'],
    #              ['2012-5-8',   '100003811911948'],
    #              ['2012-5-16',  '100003875801329']]
    #
    #  num_record = time_array.length
    #  dates=Array.new(num_record)
    #  lids = Array.new(num_record)
    #  (0..(num_record-1)).each do |i|
    #    dates[i] = Date.parse(time_array[i][0])
    #    lids[i] = time_array[i][1].to_i
    #  end
    #
    #  lidmin = 0
    #  lidmax = 0
    #  idmin = num_record -1
    #  idmax = 0
    #  lids.reverse_each do |k|
    #    if k<= lid
    #      lidmin = k
    #      break
    #    end
    #    idmin-=1
    #  end
    #
    #  lids.each do |k|
    #    if k>=lid
    #      lidmax = k
    #      break
    #    end
    #    idmax+=1
    #  end
    #
    #  createDate = 0
    #  if lidmax == lids[0] # date falls before first date available
    #    delta = lids[0]-lid
    #    create_date = dates[0] - ((delta.to_f/(lids[1]-lids[0]).to_f)*(dates[1]-dates[0])).to_i
    #  elsif lidmin==lids[-1] # date is newer then latest available date point
    #    delta = lid-lids[-1]
    #    create_date = dates[-1]+ ((delta.to_f/(lids[-1]-lids[-2]).to_f)*(dates[-1]-dates[-2])).to_i
    #  elsif lidmin==lidmax  # date falls on a record in our database
    #    create_date = dates[idmin]
    #  else    # date is in our range, so we interpolate
    #    delta = lid-lids[idmin]
    #    create_date = dates[idmin]+ ((delta.to_f/(lids[idmax]-lids[idmin]).to_f)*(dates[idmax]-dates[idmin])).to_i
    #  end
    #  return create_date
    #end

  end

  def compute_photo_engagements
    build_photo_engagements if photo_engagements.nil?
    photo_engagements.compute
  end

  def compute_status_engagements
    build_status_engagements if status_engagements.nil?
    status_engagements.compute
  end


  def field_completeness(field_name)
    completeness = self.info[field_name].nil? ? 0 : self.info[field_name].length
    completeness = completeness>0 ? 1 : 0

    return completeness
  end

  def compute_trust_score
    compute_joined_on
    page_age = Date.today - self.joined_on
    friend_count = self.class.unscoped.where(:_id=>self.to_param).only("friends").first.friends.count
    edge_count = self.class.unscoped.where(:_id=>self.to_param).only("edges").first.edges.count
    self.profile_maturity = (Math.tanh(page_age/300.0)*Math.tanh(friend_count/300.0)*80).round(0)

    profile_completeness = 0
    if self.info.present?
      has_education = field_completeness("education")
      has_location = field_completeness("location")
      has_sex = field_completeness("gender")
      has_email=field_completeness("email")
      has_website = field_completeness("website")
      has_birthday = field_completeness("birthday")
      has_bio = field_completeness("bio")
      has_verified = 0
      if self.info["verified"].present?
        has_verified = self.info["verified"]=="true" ? 1 : 0
      end
      profile_completeness =   has_education+has_location+has_sex+has_email+has_website+has_birthday+has_bio+has_verified
    end

    self.profile_maturity = self.profile_maturity + (profile_completeness * 20.0/8.0).round(0)

    puts "page age: "+page_age.to_s+" friends count: "+friend_count.to_s+ " profile maturity: "+self.profile_maturity.to_s
    # access photo engagements scores: self.photo_engagements.co_tags_uniques, etc. see methods in PhotoEngagements
    # self.trust_score = ....
    compute_photo_engagements
    compute_status_engagements

    total_likes = self.photo_engagements.likes_uniques + self.status_engagements.likes_uniques
    total_comments = self.photo_engagements.comments_uniques+self.status_engagements.comments_uniques
    total_co_tags = self.photo_engagements.co_tags_uniques

    score_likes = Math.tanh( total_likes/40.0 ) * (28.3 +5.0*rand())
    score_comments = Math.tanh(total_comments/20.0)*(28.3 +5.0*rand())
    score_co_tags = Math.tanh(total_co_tags/20.0)*(28.3 +5.0*rand())


    self.trust_score = (score_likes+score_comments+score_co_tags).to_i
    puts "Uniques: "
    puts "like: "+ total_likes.to_s + " score: "+score_likes.to_i.to_s
    puts "comments: "+total_comments.to_s+" score: "+score_comments.to_i.to_s
    puts "cotags: " + total_co_tags.to_s + " score: "+score_co_tags.to_i.to_s
    puts "trust_score: "+ trust_score.to_s


    self.user_stat = Hash.new()
    self.user_stat["num_friend"]=friend_count
    self.user_stat["num_edge"]=edge_count
    self.user_stat["profile_completeness"]= (profile_completeness * 100/8).round(0)
    self.user_stat["num_likes"]=(defined?self.likes).nil? ? 0 : self.likes.count
    self.user_stat["num_location"]=(defined?self.locations).nil? ? 0 : self.locations.count
    self.user_stat["num_photo"]=(defined?self.photos).nil? ? 0 : self.photos.count
    self.user_stat["num_posts"]=(defined?self.posts).nil? ? 0 : self.posts.count
    self.user_stat["num_status"]=(defined?self.statuses).nil? ? 0 : self.statuses.count
    self.user_stat["num_tag"]=(defined?self.tagged).nil? ? 0 : self.tagged.count

    self.user_stat["total_liked"]=total_likes
    self.user_stat["total_commented"]=total_comments
    self.user_stat["total_photo_co_tag"] = total_co_tags

    self.save
  end

  def collect_friends_location_stats
    friends = FacebookProfile.unscoped.friends_only.find(self.id).friends

    num_friends=friends.count

    location_hash = Hash.new()

    friends.each do |friend|
      location = ""
      if not(friend["current_location"].nil?)
        fb_location = friend["current_location"]
        country = fb_location["country"] || ""
        if country == "United States"
          name = fb_location["name"] || ""
          if name.blank?
            city = fb_location["city"] || ""
            state = fb_location["state"] || ""
            location = city+", " + state + ", " + country
          else
            location = name + ", " + country
          end
        else # foreign country
          name = fb_location["name"] || ""
          if name.length==0
            city = fb_location["city"] || ""
            state = fb_location["state"] || ""
            location = city+", " + state + ", " + country
          else
            location = name
          end
        end
        #puts fb_location;
        #puts location;
      end

      if location.present?
        if location_hash[location].nil?
          location_hash[location]=1
        else
          location_hash[location] = location_hash[location]+1
        end
      end
    end

    location_hash.sort_by {|name, count| count}.reverse
  end

  def geolocation_coordiates_for_friends_locations(location_hash)
    coordinate_hash = Hash.new()
    num_location = location_hash.length

    num_loc = num_location > 5 ? 4 : numlocation
    (0..num_loc).each do |i|
      location = location_hash[i][0]
      coordinate_hash[location] = Geocoder.coordinates(location)
      if i>0
        cord0 = coordinate_hash[location_hash[0][0]]
        cord1 = coordinate_hash[location_hash[i][0]]
        puts Geocoder::Calculations.distance_between(cord0, cord1)
      end
    end
  end

end