class User
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap
  
  key :uid, String
  key :provider, String
  key :image, String
  key :name, String
  key :token, String
  key :secret, String

  timestamps!

  one :linkedin_profile
  one :facebook_profile

end
