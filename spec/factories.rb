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

  factory :facebook_profile do
    friends [{"uid"=>563900754, "name"=>"Weidong Yang",
              "first_name"=>"Weidong", "last_name"=>"Yang",
              "pic"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/186383_563900754_1786047058_s.jpg", "pic_square"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/186383_563900754_1786047058_q.jpg",
              "sex"=>"male", "verified"=>nil, "likes_count"=>nil, "mutual_friend_count"=>11},
             {"uid"=>553647753, "name"=>"Lars Kamp",
              "first_name"=>"Lars", "last_name"=>"Kamp",
              "pic"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/27430_553647753_3455_s.jpg", "pic_square"=>"https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/27430_553647753_3455_q.jpg",
              "sex"=>"male", "verified"=>nil, "likes_count"=>46, "mutual_friend_count"=>2}]
    edges   [{"uid1"=>"563900754", "uid2"=>"553647753"}, {"uid1"=>"553647753", "uid2"=>"563900754"}]
    graph   '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\" xmlns:viz=\"http://www.gexf.net/1.2draft/viz\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\"></gexf>'
    labels []
    user factory: :fb_user
  end

  factory :api_client do
    name 'New Commerce, Inc.'
    api_key 'mnbvcxz0987654'
    postback_domain 'api.example.com'
  end

end
