usr=User.where(name:"Julia S.").first
fb=usr.build_facebook_profile(uid:usr.uid)
#fb=FacebookProfile.where(uid:usr.uid).first

fb.get_profile_and_network_graph!