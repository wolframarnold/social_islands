# encoding: utf-8

FactoryGirl.define do

  sequence :uid do |n|
    (123456 + n).to_s
  end

  factory :fb_user, class: User do
    uid
    name 'Joe Smith'
    provider 'facebook'
    image 'http://example.com/joesmith.png'
    token 'BCDEFG'
    secret 'HIJKLMNO'
  end

  def Factory.info_fixture(name)
    path = File.expand_path('../fixtures/facebook_info_response.json', __FILE__)
    @json ||= JSON.parse(File.read(path))[name]
  end

  def Factory.friends_fixture(name)
    path = File.expand_path('../fixtures/facebook_friends_response.json', __FILE__)
    @json_friends ||= JSON.parse(File.read(path))[name]
  end

  factory :wei_fb_profile, class: FacebookProfile do
    user factory: :fb_user#, name: info_fixture("wei")["name"]
    uid Factory.info_fixture("wei")['id']
    friends Factory.friends_fixture("wei")
    info Factory.info_fixture("wei")
  end

  factory :facebook_profile do
    user factory: :fb_user
    uid  { user.uid }
    name { user.name }
    friends [{"uid"=>'563900754', "name"=>"Weidong Yang",
              "first_name"=>"Weidong", "last_name"=>"Yang",
              "pic"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/186383_563900754_1786047058_s.jpg", "pic_square"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/186383_563900754_1786047058_q.jpg",
              "sex"=>"male", "verified"=>nil, "likes_count"=>nil, "mutual_friend_count"=>2},
             {"uid"=>'553647753', "name"=>"Lars Kamp",
              "first_name"=>"Lars", "last_name"=>"Kamp",
              "pic"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/27430_553647753_3455_s.jpg", "pic_square"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/27430_553647753_3455_q.jpg",
              "sex"=>"male", "verified"=>nil, "likes_count"=>46, "mutual_friend_count"=>2}]
    edges   [{"uid1"=>"563900754", "uid2"=>"553647753"}, {"uid1"=>"553647753", "uid2"=>"563900754"}]
    graph   '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\" xmlns:viz=\"http://www.gexf.net/1.2draft/viz\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\"></gexf>'
    labels []
    photos  { [{"id" => "10150701778989412",
               "from" => {"name" => "Yannis Adoniou's KUNST-STOFF",
                          "category" => "Non-profit organization",
                          "id" => "40981764411"},
               "name" => "Check KUNST-STOFF on the streets downtown, with Marina Fukushima!",
               "picture" => "http://photos-c.ak.fbcdn.net/hphotos-ak-prn1/535823_10150701778989412_40981764411_9417026_813474762_s.jpg",
               "source" => "http://sphotos.xx.fbcdn.net/hphotos-prn1/s720x720/535823_10150701778989412_40981764411_9417026_813474762_n.jpg",
               "height" => 641, "width" => 720, "images" => [{"height" => 1553, "width" => 1742, "source" => "http://a3.sphotos.ak.fbcdn.net/hphotos-ak-snc7/471945_10150701778989412_40981764411_9417026_813474762_o.jpg"},
                                                             {"height" => 855, "width" => 960, "source" => "http://sphotos.xx.fbcdn.net/hphotos-prn1/535823_10150701778989412_40981764411_9417026_813474762_n.jpg"},
                                                             {"height" => 641, "width" => 720, "source" => "http://sphotos.xx.fbcdn.net/hphotos-prn1/s720x720/535823_10150701778989412_40981764411_9417026_813474762_n.jpg"},
                                                             {"height" => 427, "width" => 480, "source" => "http://sphotos.xx.fbcdn.net/hphotos-prn1/s480x480/535823_10150701778989412_40981764411_9417026_813474762_n.jpg"},
                                                             {"height" => 284, "width" => 320, "source" => "http://sphotos.xx.fbcdn.net/hphotos-prn1/s320x320/535823_10150701778989412_40981764411_9417026_813474762_n.jpg"},
                                                             {"height" => 160, "width" => 180, "source" => "http://photos-c.ak.fbcdn.net/hphotos-ak-prn1/535823_10150701778989412_40981764411_9417026_813474762_a.jpg"},
                                                             {"height" => 115, "width" => 130, "source" => "http://photos-c.ak.fbcdn.net/hphotos-ak-prn1/535823_10150701778989412_40981764411_9417026_813474762_s.jpg"},
                                                             {"height" => 115, "width" => 130, "source" => "http://photos-c.ak.fbcdn.net/hphotos-ak-prn1/s75x225/535823_10150701778989412_40981764411_9417026_813474762_s.jpg"}],
               "link" => "http://www.facebook.com/photo.php?fbid=10150701778989412&set=a.57635124411.68262.40981764411&type=1",
               "icon" => "http://static.ak.fbcdn.net/rsrc.php/v1/yz/r/StEh3RhPvjk.gif",
               "created_time" => "2012-04-19T07:06:05+0000",
               "position" => 2, "updated_time" => "2012-04-19T07:06:08+0000",
               "tags" => {"data" => [{"id" => user.uid,
                                      "name" => user.name,
                                      "x" => 34.4828, "y" => 72.6937, "created_time" => "2012-04-19T07:07:55+0000"},
                                     {"id" => "589356473",
                                      "name" => "Yannis Adoniou",
                                      "x" => 58.4565, "y" => 91.5129, "created_time" => "2012-04-19T07:06:47+0000"},
                                     {"id" => "558293791",
                                      "name" => "Marina Fukushima",
                                      "x" => 49.5895, "y" => 37.2694, "created_time" => "2012-04-19T07:06:33+0000"}]},
               "comments" => {"data" => [{"id" => "10150701778989412_6371450",
                                          "from" => {"name" => user.name,
                                                     "id" => user.uid},
                                          "message" => "Do you know which part of Market St is it?",
                                          "can_remove" => true, "created_time" => "2012-04-19T07:12:05+0000"},
                                         {"id" => "10150701778989412_6371457",
                                          "from" => {"name" => "Yannis Adoniou's KUNST-STOFF",
                                                     "category" => "Non-profit organization",
                                                     "id" => "40981764411"},
                                          "message" => "Civic Center block of 7th and 8th Market!",
                                          "created_time" => "2012-04-19T07:13:47+0000"},
                                         {"id" => "10150701778989412_6371474",
                                          "from" => {"name" => "Romar Sentin-Ebalo",
                                                     "id" => "100002217497819"},
                                          "message" => "That's my girl...Beautiful!!!!",
                                          "created_time" => "2012-04-19T07:22:45+0000"},
                                         {"id" => "10150701778989412_6371491",
                                          "from" => {"name" => "Margaret Lum",
                                                     "id" => "504517003"},
                                          "message" => "YAY for Kunst-Stoff and Weidong!  Congratulations!!",
                                          "created_time" => "2012-04-19T07:25:51+0000"},
                                         {"id" => "10150701778989412_6372233",
                                          "from" => {"name" => "Daniel Oliver",
                                                     "id" => "500384038"},
                                          "message" => "Yeah!!!",
                                          "created_time" => "2012-04-19T11:14:54+0000"},
                                         {"id" => "10150701778989412_6373136",
                                          "from" => {"name" => "Raymond Fong",
                                                     "id" => "1006354328"},
                                          "message" => "Beautiful Marina!!",
                                          "created_time" => "2012-04-19T14:07:34+0000"},
                                         {"id" => "10150701778989412_6373710",
                                          "from" => {"name" => "Carin Gavin",
                                                     "id" => "100001224767136"},
                                          "message" => "Marina ! So cool!!!",
                                          "message_tags" => [{"id" => "558293791",
                                                              "name" => "Marina",
                                                              "type" => "user",
                                                              "offset" => 0, "length" => 6}],
                                          "created_time" => "2012-04-19T15:55:13+0000"},
                                         {"id" => "10150701778989412_6380573",
                                          "from" => {"name" => "Calvin Payne",
                                                     "id" => "100002047432823"},
                                          "message" => "this makes me so happy 1",
                                          "created_time" => "2012-04-20T15:50:05+0000",
                                          "likes" => 1}],
                              "paging" => {"next" => "https://graph.facebook.com/10150701778989412/comments?access_token=AAAE77rDZABK8BACHHscqqUhHtqsyWWGdChYAA71azLZBjoZBOv8T3ksHcI6lfUWefZC6qZAAVAbATgGiRbnPKWEDZCxwOoW7jSFhNOgVdZCwAZDZD&limit=25&offset=25&__after_id=10150701778989412_6380573"}},
               "likes" => {"data" => [{"id" => "13005165",
                                       "name" => "Chris DeVita"},
                                      {"id" => "100002047432823",
                                       "name" => "Calvin Payne"},
                                      {"id" => "1356153138",
                                       "name" => "Shoshana Green"},
                                      {"id" => "527391410",
                                       "name" => "Zoe Glynn"},
                                      {"id" => "655317879",
                                       "name" => "Alexi Exuzides"},
                                      {"id" => "1374922097",
                                       "name" => "Yuko Hata"},
                                      {"id" => "100001224767136",
                                       "name" => "Carin Gavin"},
                                      {"id" => "100000241077339",
                                       "name" => "Jean Henderson"},
                                      {"id" => "1616917040",
                                       "name" => "Kathy Mata"},
                                      {"id" => "620296780",
                                       "name" => "Erica Rose Jeffrey"},
                                      {"id" => "1200597914",
                                       "name" => "Emily-Ann Little"},
                                      {"id" => "755494517",
                                       "name" => "Corey Brady"},
                                      {"id" => "697597360",
                                       "name" => "Jennifer Meek"},
                                      {"id" => "1060735738",
                                       "name" => "Eleni Saloniki"},
                                      {"id" => "605639397",
                                       "name" => "Lauren Cameron Klein"},
                                      {"id" => "1006354328",
                                       "name" => "Raymond Fong"},
                                      {"id" => "1023085608",
                                       "name" => "Yukihiko Noda"},
                                      {"id" => "1349795215",
                                       "name" => "Cynthia Zoellin Grapel"},
                                      {"id" => "678314575",
                                       "name" => "Daniel Hurtado"},
                                      {"id" => "683976322",
                                       "name" => "Hannah Buckley"},
                                      {"id" => "541653582",
                                       "name" => "Pavel Machuca Zavarzina"},
                                      {"id" => "100002217497819",
                                       "name" => "Romar Sentin-Ebalo"},
                                      {"id" => "545153726",
                                       "name" => "Robin Wilson"},
                                      {"id" => "100003699763655",
                                       "name" => "Timothy Tristan"}],
                           "paging" => {"next" => "https://graph.facebook.com/10150701778989412/likes?access_token=AAAE77rDZABK8BACHHscqqUhHtqsyWWGdChYAA71azLZBjoZBOv8T3ksHcI6lfUWefZC6qZAAVAbATgGiRbnPKWEDZCxwOoW7jSFhNOgVdZCwAZDZD&limit=25&offset=25&__after_id=100003699763655"}}},
              {"id" => "426734264008786",
               "from" => {"name" => "KUNST-STOFF arts",
                          "category" => "Non-profit organization",
                          "id" => "115506808464868"},
               "name" => "check this on going April classes!",
               "picture" => "http://photos-f.ak.fbcdn.net/hphotos-ak-ash4/292531_426734264008786_115506808464868_1966400_1736310643_s.jpg",
               "source" => "http://sphotos.xx.fbcdn.net/hphotos-ash4/s720x720/292531_426734264008786_115506808464868_1966400_1736310643_n.jpg",
               "height" => 290, "width" => 720, "images" => [{"height" => 400, "width" => 990, "source" => "http://a6.sphotos.ak.fbcdn.net/hphotos-ak-ash4/460853_426734264008786_115506808464868_1966400_1736310643_o.jpg"},
                                                             {"height" => 387, "width" => 960, "source" => "http://sphotos.xx.fbcdn.net/hphotos-ash4/292531_426734264008786_115506808464868_1966400_1736310643_n.jpg"},
                                                             {"height" => 290, "width" => 720, "source" => "http://sphotos.xx.fbcdn.net/hphotos-ash4/s720x720/292531_426734264008786_115506808464868_1966400_1736310643_n.jpg"},
                                                             {"height" => 193, "width" => 480, "source" => "http://sphotos.xx.fbcdn.net/hphotos-ash4/s480x480/292531_426734264008786_115506808464868_1966400_1736310643_n.jpg"},
                                                             {"height" => 128, "width" => 320, "source" => "http://sphotos.xx.fbcdn.net/hphotos-ash4/s320x320/292531_426734264008786_115506808464868_1966400_1736310643_n.jpg"},
                                                             {"height" => 72, "width" => 180, "source" => "http://photos-f.ak.fbcdn.net/hphotos-ak-ash4/292531_426734264008786_115506808464868_1966400_1736310643_a.jpg"},
                                                             {"height" => 52, "width" => 130, "source" => "http://photos-f.ak.fbcdn.net/hphotos-ak-ash4/292531_426734264008786_115506808464868_1966400_1736310643_s.jpg"},
                                                             {"height" => 52, "width" => 130, "source" => "http://photos-f.ak.fbcdn.net/hphotos-ak-ash4/s75x225/292531_426734264008786_115506808464868_1966400_1736310643_s.jpg"}],
               "link" => "http://www.facebook.com/photo.php?fbid=426734264008786&set=a.118526884829527.20257.115506808464868&type=1",
               "icon" => "http://static.ak.fbcdn.net/rsrc.php/v1/yz/r/StEh3RhPvjk.gif",
               "created_time" => "2012-04-06T22:00:20+0000",
               "position" => 8, "updated_time" => "2012-04-06T22:00:21+0000",
               "tags" => {"data" => [{"id" => user.uid,
                                      "name" => user.name,
                                      "x" => 29.6504, "y" => 73.0104, "created_time" => "2012-04-06T22:00:48+0000"},
                                     {"id" => "568794740",
                                      "name" => "Chinchin Hsu",
                                      "x" => 12.7273, "y" => 73.0104, "created_time" => "2012-04-06T22:00:41+0000"},
                                     {"id" => "617287785",
                                      "name" => "Kathleen Hermesdorf",
                                      "x" => 55.9441, "y" => 51.9031, "created_time" => "2012-04-06T22:00:36+0000"}]},
               "comments" => {"data" => [{"id" => "426734264008786_1528041",
                                          "from" => {"name" => "Labayen Dance SF",
                                                     "id" => "540535876"},
                                          "message" => "this is awesome Weidong! I know you will be a fantastic teacher!:=) I will also spread the word around that you are teaching. :=)",
                                          "created_time" => "2012-04-06T23:27:08+0000"},
                                         {"id" => "426734264008786_1528676",
                                          "from" => {"name" => user.name,
                                                     "id" => user.uid},
                                          "message" => "Thanks Rico! :)",
                                          "can_remove" => true, "created_time" => "2012-04-07T03:23:40+0000"}],
                              "paging" => {"next" => "https://graph.facebook.com/426734264008786/comments?access_token=AAAE77rDZABK8BACHHscqqUhHtqsyWWGdChYAA71azLZBjoZBOv8T3ksHcI6lfUWefZC6qZAAVAbATgGiRbnPKWEDZCxwOoW7jSFhNOgVdZCwAZDZD&limit=25&offset=25&__after_id=426734264008786_1528676"}},
               "likes" => {"data" => [{"id" => "610867332",
                                       "name" => "Sandy Chao"},
                                      {"id" => "598322650",
                                       "name" => "Katie Griffin"},
                                      {"id" => "540535876",
                                       "name" => "Labayen Dance SF"},
                                      {"id" => "100000026271587",
                                       "name" => "Leyya Mona Tawil"},
                                      {"id" => "667152122",
                                       "name" => "Christiane Crawford"},
                                      {"id" => "544993696",
                                       "name" => "Christine Bonansea"},
                                      {"id" => "1625671516",
                                       "name" => "Kathleen O'Connor Helge"},
                                      {"id" => "629330868",
                                       "name" => "Julia Mayer"},
                                      {"id" => "1269520910",
                                       "name" => "Angie Simmons"}],
                           "paging" => {"next" => "https://graph.facebook.com/426734264008786/likes?access_token=AAAE77rDZABK8BACHHscqqUhHtqsyWWGdChYAA71azLZBjoZBOv8T3ksHcI6lfUWefZC6qZAAVAbATgGiRbnPKWEDZCxwOoW7jSFhNOgVdZCwAZDZD&limit=25&offset=25&__after_id=1269520910"}}}
             ] }
  end

  factory :api_client do
    name 'New Commerce, Inc.'
    api_key 'mnbvcxz0987654'
    postback_domain 'api.example.com'
  end

end
