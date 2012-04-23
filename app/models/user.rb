class User
  include MongoMapper::Document

  key :uid, String
  key :provider, String
  key :image, String
  key :name, String
  key :token, String
  key :secret, String

  timestamps!

  one :facebook_profile

end
