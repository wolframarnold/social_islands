FactoryGirl.define do

  factory :user do
    sequence(:uid) { |i| i}
    name 'Joe Smith'
    provider 'linkedin'
    image 'http://example.com/joesmith.png'
    token 'ABCDEF'
    secret 'GHIJKLMN'
  end

end
