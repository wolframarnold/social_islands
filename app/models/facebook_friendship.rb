class FacebookFriendship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :facebook_profile_from, class_name: 'FacebookProfile', inverse_of: :facebook_profile
  belongs_to :facebook_profile_to, class_name: 'FacebookProfile', inverse_of: :facebook_profile

  field :can_post,            type: Boolean
  field :mutual_friend_count, type: Integer

  index [ [ :facebook_profile_from, Mongo::ASCENDING ],
          [ :facebook_profile_to, Mongo::ASCENDING ] ],
        unique: true

  validates :facebook_profile_from_id, :facebook_profile_to_id, presence: true

end