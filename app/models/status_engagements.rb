#class StatusEngagements
#
#  include Mongoid::Document
#
#  field :uid,            type: String
#  field :name,           type: String
#  field :liked_by,       type: Hash
#  field :commented_by,   type: Hash
#
#  belongs_to :facebook_profile, polymorphic: true, index: true
#
#  validates :facebook_profile, presence: true
#
#  before_validation :populate_name_uid_image
#  #
#  #def compute
#  #  return if facebook_profile.photos.nil?
#  #  initial = { liked_by: {}, commented_by: {} }
#  #  results = facebook_profile.statuses.reduce(initial) do |stats, status|
#  #    # TODO: Deal with case when the tagged party doesn't have a UID (i.e. is not on FB)
#  #    # See tracker story: https://www.pivotaltracker.com/story/show/29603637
#  #    add_engagements(stats[:liked_by], status, 'likes')
#  #    add_engagements(stats[:commented_by], status, 'comments')
#  #    stats
#  #  end
#  #  self.attributes = results  # assigns the three attribute to this MongoDB record
#  #  self
#  #end
#  #
#  #def likes_uniques
#  #  self.liked_by.length
#  #end
#  #
#  #def comments_uniques
#  #  self.commented_by.length
#  #end
#  #
#  #def likes_total
#  #  self.liked_by.sum {|attr, val| val}
#  #end
#  #
#  #def comments_total
#  #  self.commented_by.sum {|attr, val| val}
#  #end
#  #
#  #private
#  #
#  #def populate_name_uid_image
#  #  self.name = facebook_profile.name
#  #  self.uid = facebook_profile.uid
#  #end
#  #
#  #def add_engagements(result, raw_data_hash, engagement_name)
#  #  return if raw_data_hash[engagement_name].nil?
#  #  raw_data_hash[engagement_name]['data'].each do |eng|
#  #    # Comments has an additional sub-hash "from"
#  #    friend_uid = engagement_name == 'comments' ? eng['from']['id'] : eng['id']
#  #    next if friend_uid.nil?  # TODO: record this case (name only, no ID -- non-FB member)
#  #                             # see story: https://www.pivotaltracker.com/story/show/29603637
#  #    next if friend_uid == facebook_profile.uid
#  #    result[friend_uid] ||= 0  # ||= sets the value, only if the left-hand-side is nil
#  #    result[friend_uid] += 1
#  #  end
#  #end
#
#end
