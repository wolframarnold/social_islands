class ApiClient

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,            type: String
  field :app_id,         type: String
  field :postback_domain, type: String

  index :app_id, unique: true
  index :name

  attr_accessible :name, :postback_domain

  validates :name, :app_id, presence: true

  #has_and_belongs_to_many :users, dependent: :nullify, index: true

end