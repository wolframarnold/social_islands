class FacebookGraph

  include Mongoid::Document
  include Mongoid::Timestamps

  field :gexf, type: String

  belongs_to :facebook_profile, index: true

  embeds_many :labels, class_name: 'FacebookGraphLabel', inverse_of: :facebook_graph

  scope :without_gexf, without(:gexf)

end