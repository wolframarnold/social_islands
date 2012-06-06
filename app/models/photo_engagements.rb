class PhotoEngagements

  include Mongoid::Document

  field :uid,            type: String
  field :name,           type: String
  field :co_tagged_with, type: Hash
  field :liked_by,       type: Hash
  field :commented_by,   type: Hash

  belongs_to :facebook_profile, polymorphic: true, index: true

  validates :facebook_profile, presence: true

  before_validation :populate_name_uid_image

  def compute
    return if facebook_profile.photos.nil?
    initial = { co_tagged_with: {}, liked_by: {}, commented_by: {} }
    results = facebook_profile.photos.reduce(initial) do |stats, photo|
      # TODO: Deal with case when the tagged party doesn't have a UID (i.e. is not on FB)
      # See tracker story: https://www.pivotaltracker.com/story/show/29603637
      add_engagements(stats[:co_tagged_with], photo, 'tags')
      add_engagements(stats[:liked_by], photo, 'likes')
      add_engagements(stats[:commented_by], photo, 'comments')
      stats
    end
    self.attributes = results  # assigns the three attribute to this MongoDB record
    self
  end

  def co_tags_uniques
    self.co_tagged_with.present? ? self.co_tagged_with.length : 0
  end

  def likes_uniques
    self.liked_by.present? ? self.liked_by.length : 0
  end

  def comments_uniques
    self.commented_by.present? ? self.commented_by.length : 0
  end

  def co_tags_total
    self.co_tagged_with.present? ? self.co_tagged_with.sum {|attr, val| val} : 0
  end

  def likes_total
    self.liked_by.present? ? self.liked_by.sum {|attr, val| val} : 0
  end

  def comments_total
    self.commented_by.present? ? self.commented_by.sum {|attr, val| val} : 0
  end

  private

  def populate_name_uid_image
    self.name = facebook_profile.name
    self.uid = facebook_profile.uid
  end

  def add_engagements(result, raw_data_hash, engagement_name)
    return if raw_data_hash[engagement_name].nil?
    raw_data_hash[engagement_name]['data'].each do |eng|
      # Comments has an additional sub-hash "from"
      # found a case where no "from" field exist name: "Robert Equality Berliner" 2400261
      friend_uid = engagement_name == 'comments' ? (eng['from'].present? ? eng['from']['id'] : '0') : eng['id']
      next if friend_uid.nil?  # TODO: record this case (name only, no ID -- non-FB member)
                               # see story: https://www.pivotaltracker.com/story/show/29603637
      next if friend_uid == facebook_profile.uid
      result[friend_uid] ||= 0  # ||= sets the value, only if the left-hand-side is nil
      result[friend_uid] += 1
    end
  end

end
