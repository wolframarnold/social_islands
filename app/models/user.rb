class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid,        type: String
  field :provider,   type: String
  field :image,      type: String
  field :name,       type: String
  field :token,      type: String
  field :secret,     type: String
  field :expires_at, type: DateTime
  field :expires,    type: Boolean

  index [[:uid, Mongo::ASCENDING], [:provider, Mongo::ASCENDING]], unique: true
  index [[:token, Mongo::ASCENDING], [:provider, Mongo::ASCENDING]], unique: true
  index :name
  index [[:created_at, Mongo::DESCENDING]]

  attr_accessible :uid, :provider, :image, :name

  # TODO: should we always require a name ? Not available for API clients
  validates :uid, :provider, :token, presence: true

  has_one :facebook_profile, dependent: :nullify, autosave: true
  has_and_belongs_to_many :api_clients, dependent: :nullify, index: true

end
