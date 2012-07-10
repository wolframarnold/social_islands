
def get_and_save_friends_feed(name)
  usr=User.where(name:name).first
  fb=FacebookProfile.unscoped.where(user_id:usr._id).first
  @graph=Koala::Facebook::API.new(usr.token)

  friends=fb.friends
  (0..(friends.count-1)).each do |i1|
    friend = friends[i1]
    if friend["feed"].blank?
      feed=@graph.get_connection(friend["uid"], "feed")
      friend["feed"]=feed
    end
    puts i1.to_s+"  "+(friend["feed"].blank? ? 0 : friend["feed"].count).to_s
  end
  fb.feed=@graph.get_connection("me", "feed")
  fb.save!
end
