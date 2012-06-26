class FacebookFriendship
  include Mongoid::Document
  include Mongoid::Timestamps

  field :can_post,                  type: Boolean
  field :mutual_friend_count,       type: Integer
  field :facebook_profile_from_uid, type: Integer
  field :facebook_profile_to_uid, type: Integer

  index :facebook_profile_from_uid, unique: true
  index :facebook_profile_to_uid, unique: true

  validates :facebook_profile_from_uid, :facebook_profile_to_uid, presence: true

  scope :from, lambda { |facebook_profile| where(facebook_profile_from_uid: facebook_profile.uid) }

end