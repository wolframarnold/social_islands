namespace :exp do
  desc "Output user stats as CSV, specify file name with OUTPUT, user name with USERNAME"
  task :csv => :environment do
    open(ENV['OUTPUT'] || 'summary.csv', 'w') do |f|
      f<< 'fbid,fbmaturity,fbtrust,faceOnProfile'
      fb=FacebookProfile.where(name: ENV["USERNAME"] || "Weidong Yang").first
      fb.user_stat.each do |k, v|
        f << ','+k
      end
      f<<"\n"
      User.all.map do |usr|
        fb=FacebookProfile.where(uid:usr.uid).first
        if fb.present?
          if fb.user_stat.present?
            f<< "fb-"+fb.uid.to_s+","
            f<< fb.profile_maturity.to_s+","+fb.trust_score.to_s+","+fb.face_detect_score
            fb.user_stat.each do |k, v|
              f<< ","+v.to_s
            end
            f<<"\n"
          end
        end
      end
    end
  end
end
