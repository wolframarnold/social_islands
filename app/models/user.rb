class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid,      type: String
  field :provider, type: String
  field :image,    type: String
  field :name,     type: String
  field :token,    type: String
  field :secret,   type: String

  index [:uid, :provider], unique: true

  attr_accessible :uid, :provider, :image, :name

  validates :uid, :provider, :image, :name, :token, :secret, presence: true

  has_one :facebook_profile, dependent: :nullify

end
