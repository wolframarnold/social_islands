feed_status1={"id"=>"589356473_10151069411601474",
              "from"=>{"name"=>"Yannis Adoniou", "id"=>"589356473"},
              "to"=>
                  {"data"=>
                       [{"name"=>"Christin Hanna", "id"=>"576360238"},
                        {"name"=>"Constantine Baecher", "id"=>"549889713"},
                        {"name"=>"Daiane Lopes da Silva", "id"=>"1512230260"},
                        {"name"=>"Risa Larsen", "id"=>"587295611"},
                        {"name"=>"Katie Gaydos", "id"=>"529597586"},
                        {"name"=>"Bruno Miguel Pereira Augusto", "id"=>"1275439091"}]},
              "message"=>
                  "...what an amazing night in Lake Tahoe thank you, Christin Hanna, Constantine Baecher with Daiane Lopes da Silva, Risa Larsen, Katie Gaydos and Bruno Miguel Pereira Augusto!",
              "message_tags"=>
                  {"50"=>
                       [{"id"=>"576360238",
                         "name"=>"Christin Hanna",
                         "type"=>"user",
                         "offset"=>50,
                         "length"=>14}],
                   "66"=>
                       [{"id"=>"549889713",
                         "name"=>"Constantine Baecher",
                         "type"=>"user",
                         "offset"=>66,
                         "length"=>19}],
                   "91"=>
                       [{"id"=>"1512230260",
                         "name"=>"Daiane Lopes da Silva",
                         "type"=>"user",
                         "offset"=>91,
                         "length"=>21}],
                   "114"=>
                       [{"id"=>"587295611",
                         "name"=>"Risa Larsen",
                         "type"=>"user",
                         "offset"=>114,
                         "length"=>11}],
                   "127"=>
                       [{"id"=>"529597586",
                         "name"=>"Katie Gaydos",
                         "type"=>"user",
                         "offset"=>127,
                         "length"=>12}],
                   "144"=>
                       [{"id"=>"1275439091",
                         "name"=>"Bruno Miguel Pereira Augusto",
                         "type"=>"user",
                         "offset"=>144,
                         "length"=>28}]},
              "actions"=>
                  [{"name"=>"Comment",
                    "link"=>"http://www.facebook.com/589356473/posts/10151069411601474"},
                   {"name"=>"Like",
                    "link"=>"http://www.facebook.com/589356473/posts/10151069411601474"}],
              "type"=>"status",
              "created_time"=>"2012-06-24T07:47:46+0000",
              "updated_time"=>"2012-06-24T07:47:46+0000",
              "likes"=>
                  {"data"=>
                       [{"name"=>"Daiane Lopes da Silva", "id"=>"1512230260"},
                        {"name"=>"Katie Gaydos", "id"=>"529597586"},
                        {"name"=>"Christin Hanna", "id"=>"576360238"},
                        {"name"=>"Bruno Miguel Pereira Augusto", "id"=>"1275439091"},
                        {"name"=>"Risa Larsen", "id"=>"587295611"}],
                   "count"=>7},
              "comments"=>{"count"=>0}}

uid="589356473"
$node_map=get_node_map;
check_feed(uid, feed_status1)
pp $node_map[uid].liked_by==["1512230260", "529597586", "576360238", "1275439091", "587295611"]
pp $node_map[uid].message_to==
       ["576360238",
        "549889713",
        "1512230260",
        "587295611",
        "529597586",
        "1275439091"]

pp $node_map["1512230260"].message_from==["589356473"]
pp $node_map["1512230260"].liked_to==["589356473"]
