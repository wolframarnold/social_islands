class Label
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :facebook_profile, inverse_of: :labels

  field :name,        type: String
  field :group_index, type: Integer
  field :color,       type: Hash
end