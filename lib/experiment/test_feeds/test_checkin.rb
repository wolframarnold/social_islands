feed_checkin_from_others={"id"=>"589356473_10151071014321474",
      "from"=>{"name"=>"Risa Larsen", "id"=>"587295611"},
      "to"=>
          {"data"=>
               [{"name"=>"Katie Gaydos", "id"=>"529597586"},
                {"name"=>"Yannis Adoniou", "id"=>"589356473"}]},
      "with_tags"=>
          {"data"=>
               [{"name"=>"Katie Gaydos", "id"=>"529597586"},
                {"name"=>"Yannis Adoniou", "id"=>"589356473"}]},
      "picture"=>
          "http://profile.ak.fbcdn.net/static-ak/rsrc.php/v2/yW/r/U2hFrus9i5v.png",
      "link"=>
          "http://www.facebook.com/pages/Temple-Fine-Coffee-and-Tea/180409905312322",
      "name"=>"Temple Fine Coffee and Tea",
      "caption"=>"Risa checked in at Temple Fine Coffee and Tea.",
      "icon"=>"http://www.facebook.com/images/icons/place.png",
      "actions"=>
          [{"name"=>"Comment",
            "link"=>"http://www.facebook.com/589356473/posts/10151071014321474"},
           {"name"=>"Like",
            "link"=>"http://www.facebook.com/589356473/posts/10151071014321474"}],
      "place"=>
          {"id"=>"180409905312322",
           "name"=>"Temple Fine Coffee and Tea",
           "location"=>
               {"street"=>"1010 9th Street",
                "city"=>"Sacramento",
                "state"=>"CA",
                "country"=>"United States",
                "zip"=>"95814",
                "latitude"=>38.580340398364,
                "longitude"=>-121.49492623839}},
      "type"=>"checkin",
      "application"=>
          {"name"=>"Facebook for iPhone", "namespace"=>"fbiphone", "id"=>"6628568379"},
      "created_time"=>"2012-06-24T23:56:58+0000",
      "updated_time"=>"2012-06-24T23:56:58+0000",
      "likes"=>
          {"data"=>
               [{"name"=>"Amanda Egron", "id"=>"1527009155"},
                {"name"=>"Jennifer Polyocan", "id"=>"621832377"},
                {"name"=>"Edera White", "id"=>"1303572108"},
                {"name"=>"Deeci Gray-Schlink", "id"=>"1094725835"}],
           "count"=>11},
      "comments"=>{"data"=>
                       [{"id"=>"1449848433_3493874272800_3488777",
                         "from"=>{"name"=>"Deeci Gray-Schlink", "id"=>"1094725835"},
                         "message"=>"Welcome home!",
                         "created_time"=>"2012-06-27T15:15:40+0000",
                         "likes"=>1},
                        {"id"=>"1449848433_3493874272800_3488780",
                         "from"=>{"name"=>"Liezl Austria", "id"=>"1449848433"},
                         "message"=>"Thanks Deeci! :)",
                         "created_time"=>"2012-06-27T15:16:57+0000"}],
                   "count"=>2}}


feed_checkin_self={"id"=>"1449848433_3493874272800",
                   "from"=>{"name"=>"Liezl Austria", "id"=>"1449848433"},
                   "message"=>"At last, after travelling for 20 hours. So glad to be back!!",
                   "picture"=>
                       "http://profile.ak.fbcdn.net/hprofile-ak-snc4/161976_110504348969090_788210797_q.jpg",
                   "link"=>"http://www.facebook.com/flySFO",
                   "name"=>"San Francisco International Airport (SFO)",
                   "caption"=>"Liezl checked in at San Francisco International Airport (SFO).",
                   "icon"=>
                       "http://photos-a.ak.fbcdn.net/photos-ak-snc7/v27562/151/2254487659/app_2_2254487659_1473.gif",
                   "actions"=>
                       [{"name"=>"Comment",
                         "link"=>"http://www.facebook.com/1449848433/posts/3493874272800"},
                        {"name"=>"Like",
                         "link"=>"http://www.facebook.com/1449848433/posts/3493874272800"}],
                   "place"=>
                       {"id"=>"110504348969090",
                        "name"=>"San Francisco International Airport (SFO)",
                        "location"=>
                            {"street"=>"McDonnell Rd & Link Rd.",
                             "city"=>"San Francisco",
                             "state"=>"CA",
                             "country"=>"United States",
                             "zip"=>"94128",
                             "latitude"=>37.616907766591,
                             "longitude"=>-122.38673789737}},
                   "type"=>"checkin",
                   "application"=>{"name"=>"BlackBerry Smartphones App", "id"=>"2254487659"},
                   "created_time"=>"2012-06-27T06:12:28+0000",
                   "updated_time"=>"2012-06-27T15:16:57+0000",
                   "likes"=>
                       {"data"=>
                            [{"name"=>"Amanda Egron", "id"=>"1527009155"},
                             {"name"=>"Jennifer Polyocan", "id"=>"621832377"},
                             {"name"=>"Edera White", "id"=>"1303572108"},
                             {"name"=>"Deeci Gray-Schlink", "id"=>"1094725835"}],
                        "count"=>11},
                   "comments"=>
                       {"data"=>
                            [{"id"=>"1449848433_3493874272800_3488777",
                              "from"=>{"name"=>"Deeci Gray-Schlink", "id"=>"1094725835"},
                              "message"=>"Welcome home!",
                              "created_time"=>"2012-06-27T15:15:40+0000",
                              "likes"=>1},
                             {"id"=>"1449848433_3493874272800_3488780",
                              "from"=>{"name"=>"Liezl Austria", "id"=>"1449848433"},
                              "message"=>"Thanks Deeci! :)",
                              "created_time"=>"2012-06-27T15:16:57+0000"}],
                        "count"=>2}}



uid="589356473"
$node_map=get_node_map;
check_feed(uid, feed_checkin_from_others)
pp $node_map[uid].commented_by==["1094725835", "1449848433"]
pp $node_map[uid].liked_by==["1527009155", "621832377", "1303572108", "1094725835"]
pp $node_map[uid].co_checkin_with==["529597586"]
pp $node_map["587295611"].checkin_others==["529597586", "589356473"]

pp $node_map["1449848433"].commented_to==["589356473"]

uid="1449848433"
$node_map=get_node_map;
check_feed(uid, feed_checkin_self)
pp $node_map[uid].commented_by==["1094725835", "1449848433"]
pp $node_map[uid].liked_by==["1527009155", "621832377", "1303572108", "1094725835"]
