namespace :stats do

  def find_profile
    fb_uid = ENV['FACEBOOK_UID']
    fb_profile_id = ENV['FACEBOOK_PROFILE_ID']
    raise "Specify FACEBOOK_PROFILE_ID=mmmm (Mongo) or (FB) FACEBOOK_UID=nnnn (FB UID) as environment variable for user to process" unless fb_uid.present? || fb_profile_id.present?
    if fb_uid.present?
      fp = FacebookProfile.where(uid: fb_uid).first
      raise "No FB Profile record with FACEBOOK_UID=#{fb_uid} found!" if fp.nil?
    else
      fp = FacebookProfile.where(id: fb_profile_id).first
      raise "No FB Profile record with FACEBOOK_PROFILE_ID=#{fb_profile_id} found!" if fp.nil?
    end
    fp
  end

  desc "Photo engagement stats, specify FACEBOOK_PROFILE_ID=mmmm (Mongo) or FACEBOOK_UID=nnnn (FB) on command line"
  task engagements: :environment do
    fp = find_profile
    fp.compute_engagements
    puts "Photo engagement stats for #{fp.name}, FACEBOOK_UID: #{fp.uid}, #{fp.photos.length} photos"
    puts "#{fp.status_engagements['co_tags_total']} total co-tags by #{fp.status_engagements['co_tags_uniques']} unique actors"
    puts "#{fp.status_engagements['likes_total']} total likes by #{fp.status_engagements['likes_uniques']} unique actors"
    puts "#{fp.status_engagements['comments_total']} total comments by #{fp.status_engagements['comments_uniques']} unique actors"
    puts "Status engagement stats for #{fp.name}, FACEBOOK_UID: #{fp.uid}, #{fp.statuses.length} status updates"
    puts "#{fp.status_engagements['co_tags_total']} total co-tags by #{fp.status_engagements['co_tags_uniques']} unique actors"
    puts "#{fp.status_engagements['likes_total']} total likes by #{fp.status_engagements['likes_uniques']} unique actors"
    puts "#{fp.status_engagements['comments_total']} total comments by #{fp.status_engagements['comments_uniques']} unique actors"
  end

end