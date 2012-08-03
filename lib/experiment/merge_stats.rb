fb=FacebookProfile.where(name:"Weidong Yang").first


fb.compute_engagements

fb.photo_engagements    #co_tagged_with, liked_by, commented_by, from
fb.status_engagements   #like comments
fb.location_engagements #co_tagged_with, from
fb.tagged_engagements   #liked_by, commented_by, from

