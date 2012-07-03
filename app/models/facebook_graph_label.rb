class FacebookGraphLabel
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :facebook_graph, inverse_of: :labels

  field :name,        type: String
  field :group_index, type: Integer
  field :color,       type: Hash
end