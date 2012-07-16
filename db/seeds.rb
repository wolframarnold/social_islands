# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
api_client = ApiClient.where(name: 'Social Islands', api_key: SOCIAL_ISLANDS_TRUST_CC_API_KEY).first
if api_client.nil?
  case Rails.env
    when 'development'
      postback_domain = 'localhost'
    when 'production'
      postback_domain = 'socialislands.org'
    when 'test'
      postback_domain = 'test.host'
    else
      raise "Unknown environment -- don't know what postback_domain to use in seeds.rb"
  end
  api_client = ApiClient.new(name: 'Social Islands', postback_domain: postback_domain)
  api_client.api_key = SOCIAL_ISLANDS_TRUST_CC_API_KEY
  api_client.save!
end
