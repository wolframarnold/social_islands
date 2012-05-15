namespace :engagements do

  def find_profile
    uid = ENV['UID']
    user_id = ENV['USER_ID']
    raise "Specify USER_ID=mmmm or (FB) UID=nnnn as environment variable for user to process" unless uid.present? || user_id.present?
    if uid.present?
      fp = FacebookProfile.where(uid: uid).first
      raise "No FB Profile record with UID=#{uid} found!" if fp.nil?
    else
      fp = FacebookProfile.where(user_id: user_id).first
      raise "No FB Profile record with USER_ID=#{user_id} found!" if fp.nil?
    end
    fp.compute_photo_engagements
    fp
  end

  desc "Photo engagement stats, specify USER_ID=mmmm or (FB) UID=nnnn on command line"
  task photos: :environment do
    fp = find_profile
    pe = fp.photo_engagements
    puts "Photo engagement stats for #{fp.name}, UID: #{fp.uid}"
    puts "#{pe.co_tags_total} total co-tags by #{pe.co_tags_uniques} unique actors on #{fp.photos.length} photos"
    puts "#{pe.likes_total} total likes by #{pe.likes_uniques} unique actors on #{fp.photos.length} photos"
    puts "#{pe.comments_total} total comments by #{pe.comments_uniques} unique actors on #{fp.photos.length} photos"
  end

end