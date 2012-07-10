feed_photo_upload={"id"=>"589356473_10151073646321474",
                   "from"=>{"name"=>"Yannis Adoniou", "id"=>"589356473"},
                   "message"=>
                       "if you missed (moNONs), you have a chance to check it out this Wednesday at 6:30pm  as KUNST-STOFF arts and Central Market Community Benefit District is hosting a free MIX&MEET event as part of DANCE/USA conference.\r\nLight snacks and refreshments will be offered :)\r\n@ KUNST-STOFF arts",
                   "picture"=>
                       "http://photos-c.ak.fbcdn.net/hphotos-ak-snc7/311550_10151073646271474_1653451515_s.jpg",
                   "link"=>
                       "http://www.facebook.com/photo.php?fbid=10151073646271474&set=a.115667616473.120103.589356473&type=1&relevant_count=1",
                   "icon"=>"http://static.ak.fbcdn.net/rsrc.php/v2/yz/r/StEh3RhPvjk.gif",
                   "actions"=>
                       [{"name"=>"Comment",
                         "link"=>"http://www.facebook.com/589356473/posts/10151073646321474"},
                        {"name"=>"Like",
                         "link"=>"http://www.facebook.com/589356473/posts/10151073646321474"}],
                   "type"=>"photo",
                   "object_id"=>"10151073646271474",
                   "created_time"=>"2012-06-26T03:55:16+0000",
                   "updated_time"=>"2012-06-26T14:34:34+0000",
                   "likes"=>
                       {"data"=>
                            [{"name"=>"Jim Tobin", "id"=>"100000590912119"},
                             {"name"=>"Alex Feng", "id"=>"1090313657"},
                             {"name"=>"Simone Marques", "id"=>"100000170201200"},
                             {"name"=>"Leyya Mona Tawil", "id"=>"100000026271587"}],
                        "count"=>15},
                   "comments"=>
                       {"data"=>
                            [{"id"=>"589356473_10151073646321474_8067463",
                              "from"=>{"name"=>"Robin Bisio", "id"=>"652480921"},
                              "message"=>
                                  "In santa Barbara admiring sparkles and modified skirt tutus and yes a perched fourth!",
                              "created_time"=>"2012-06-26T14:02:51+0000"},
                             {"id"=>"589356473_10151073646321474_8067640",
                              "from"=>{"name"=>"Erik Wagner", "id"=>"531055269"},
                              "message"=>"great pic.",
                              "created_time"=>"2012-06-26T14:34:34+0000"}],
                        "count"=>9}}

uid="589356473"

$node_map=get_node_map;
check_feed(uid, feed_photo_upload)
pp $node_map[uid].commented_by==["652480921", "531055269"]
pp $node_map[uid].liked_by==["100000590912119", "1090313657", "100000170201200", "100000026271587"]