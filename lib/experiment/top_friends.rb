#Find out which friends have the most photo cotag, tagging, like, comment

fb=FacebookProfile.where(name:"Weidong Yang").first



fb.compute_engagements

fb.photo_engagements
fb.status_engagements
fb.location_engagements
fb.tagged_engagements