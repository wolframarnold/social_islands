class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :image,      type: String
  field :name,       type: String

  index :name
  index [[:created_at, Mongo::DESCENDING]]

  attr_accessible :image, :name

  has_many :facebook_profiles, dependent: :nullify#, autosave: true

end
