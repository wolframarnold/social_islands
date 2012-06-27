class FacebookGraph

  include Mongoid::Document
  include Mongoid::Timestamps

  field :gexf, type: String

  belongs_to :facebook_profile, index: true
  embeds_many :facebook_graph_labels, inverse_of: :facebook_graph

end