class ApiClient

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,            type: String
  field :api_key,         type: String
  field :postback_domain, type: String

  index :api_key, unique: true

  attr_accessible :name, :postback_domain

  validates :name, :api_key, :postback_domain, presence: true

  has_and_belongs_to_many :users, dependent: :nullify, index: true

end