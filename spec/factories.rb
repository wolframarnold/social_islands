# encoding: utf-8

def FactoryGirl.fb_credentials(name)
  @fb_credentials ||= YAML.load_file(File.expand_path('../fixtures/facebook_credentials.yml', __FILE__))
  @fb_credentials[name.to_s]
end

def FactoryGirl.info_fixture(name)
  path = File.expand_path('../fixtures/facebook_info_response.json', __FILE__)
  @json ||= JSON.parse(File.read(path))
  @json[name.to_s]
end

def FactoryGirl.friends_fixture(name)
  path = File.expand_path('../fixtures/facebook_friends_response.json', __FILE__)
  @json_friends ||= JSON.parse(File.read(path))
  @json_friends[name.to_s]
end

FactoryGirl.define do

  sequence :uid do |n|
    (123456 + n).to_s
  end

  factory :fb_user, class: User do
    name 'Joe Smith'
    image 'http://example.com/joesmith.png'
  end

  factory :wolf_user, parent: :fb_user do
    name wolf_credentials = FactoryGirl.fb_credentials(:wolf)['name']
    image 'http://example.com/wolf.png'
  end

  factory :wei_facebook_profile, class: FacebookProfile do
    name 'Weidong Yang'
    uid FactoryGirl.fb_credentials(:wei)['uid']
    image 'https://faceboom.com/weidong.png'
    user factory: :wolf_user, image: 'https://faceboom.com/weidong.png'
    token FactoryGirl.fb_credentials(:wei)['token']
    app_id '66b53220'
    about_me FactoryGirl.info_fixture("wei")
    after(:create) do |wei_fp|
      create(:api_client, app_id: wei_fp.app_id)
    end
  end

  factory :wolf_facebook_profile, class: FacebookProfile do
    name 'Wolfram Arnold'
    uid 595045215
    image 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/371822_595045215_1563438209_q.jpg'
    user factory: :wolf_user, image: 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/371822_595045215_1563438209_q.jpg'
    token FactoryGirl.fb_credentials(:wolf)['token']
    app_id '66b53220'
    fetched_directly true

    after(:create) do |wolf_fp|
      create(:api_client, app_id: wolf_fp.app_id)
    end
  end

  factory :facebook_graph do
    facebook_profile factory: :wolf_facebook_profile
    gexf '<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\" xmlns:viz=\"http://www.gexf.net/1.2draft/viz\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\"></gexf>'
  end

  factory :api_client do
    name 'New Commerce, Inc.'
    app_id '66b53220'
    postback_domain 'api.example.com'
  end

end
