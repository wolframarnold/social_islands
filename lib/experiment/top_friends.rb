#Find out which friends have the most photo cotag, tagging, like, comment

fb=FacebookProfile.where(name:"Weidong Yang").first
fb.compute_top_friends


fb.compute_engagements

fb.photo_engagements    #co_tagged_with, liked_by, commented_by, from
fb.status_engagements   #like comments
fb.location_engagements #co_tagged_with, from
fb.tagged_engagements   #liked_by, commented_by, from


#merge and sort photo_from, location_from, tagged_from
#merge and sort photo_cotag, location_cotag
#merge and sort photo_like,

#weights

w_photo_like = 1
w_photo_comment = 1
w_photo_cotag = 1
w_photo_from = 3

w_status_like = 2
w_status_comment = 4

w_location_cotag = 2
w_location_from = 4

w_tagged_like = 2
w_tagged_comment = 3
w_tagged_from = 4

def hash_merge(h1, w_h1, h2, w_h2)
  new_hash=Hash.new(0)
  h1.each {|key, val| new_hash[key]+=val*w_h1}
  h2.each {|key, val| new_hash[key]+=val*w_h2}
  return new_hash
end

co_tag=hash_merge(fb.photo_engagements['co_tagged_with'], w_photo_cotag, fb.location_engagements['co_tagged_with'], w_location_cotag)

from=hash_merge(fb.photo_engagements['from'], w_photo_from, fb.location_engagements['from'], w_location_from)
from=hash_merge(from, 1, fb.tagged_engagements['from'], w_tagged_from)

liked_by=hash_merge(fb.photo_engagements['liked_by'], w_photo_like, fb.status_engagements['liked_by'], w_status_like)
liked_by=hash_merge(liked_by, 1, fb.tagged_engagements['liked_by'], w_tagged_like)

commented_by=hash_merge(fb.photo_engagements['commented_by'], w_photo_comment, fb.status_engagements['commented_by'], w_status_comment)
commented_by=hash_merge(commented_by, 1, fb.tagged_engagements['commented_by'], w_tagged_comment)

in_bound=hash_merge(co_tag, 1, from, 1)
in_bound=hash_merge(in_bound, 1, liked_by, 1)
in_bound=hash_merge(in_bound, 1, commented_by, 1)
in_bound.delete("")
in_bound=in_bound.sort_by{|key, val| -val}


in_bound[0..20].each do |key, val|
  name=FacebookProfile.where(uid:key).blank? ? " " : FacebookProfile.where(uid:key).first['name']
  puts name+" "+ val.to_s + " " + key
end


###########################################
#       Testing Laura's profile           #
###########################################
fb=FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(:token=>"AAAE77rDZABK8BAPgFKWCzmy4ZAu6ZBdGyJ6XjIWGZCcKQZCnKfeZBrzSArOZBKIYA85CvcdDm8I2kBAPVnO9JtMUm5qOHZChXS1DMha3kIPRYgZDZD", :app_id=>"weitest")
fb.import_profile_and_network!

fb=FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(:token=>"AAAE77rDZABK8BAJovOXQBffeVo3tfdoIeEHpgAncNjZCpamKWgp7JA1LCwe3DRBwoToZA07p1RRdj8wos6EHBijaVO9bS6QtoqF0XphAQZDZD", :app_id=>"weitest")

fb=FacebookProfile.where(name:"Laura Rae Bernasconi").last
fb=FacebookProfile.where(name:"Daiane Lopes da Silva").last

fb=FacebookProfile.where(name:"Weidong Yang").first
fb.compute_top_friends
msgs=fb.statuses.map {|s| s['message']}


conn = Faraday.new(:url => 'http://djangocc.herokuapp.com') do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

msgs.map do |text|
  text=text.scan(/[a-zA-Z '0-9]/).join
  #text=msgs[0].gsub( /\n/m, " ")
  text.gsub!(/ /, "%20")
  #response = conn.get '/alert/'+text
  response = conn.get '/sentiment/'+text
  puts response.body
  puts " "
end
