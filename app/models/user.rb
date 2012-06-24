class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # TODO: Move uid, provider out of here, should only reside in FB Profile
  # Move token into a TokenSource table
  field :uid,        type: String
  field :provider,   type: String
  field :image,      type: String
  field :name,       type: String
  field :token,      type: String
  field :secret,     type: String
  field :expires_at, type: DateTime
  field :expires,    type: Boolean

  index [[:uid, Mongo::ASCENDING], [:provider, Mongo::ASCENDING]], unique: true
  index [[:token, Mongo::ASCENDING], [:provider, Mongo::ASCENDING]], unique: true
  index :name
  index [[:created_at, Mongo::DESCENDING]]

  attr_accessible :uid, :provider, :image, :name

  validates :uid, :provider, :token, presence: true

  has_one :facebook_profile, dependent: :nullify, autosave: true
  has_and_belongs_to_many :api_clients, dependent: :nullify, index: true

  def self.find_or_create_with_facebook_profile_by_uid(params)
    # Note: Mongoid's find_or_create is NOT atomic!!! Not sure why. See: http://stackoverflow.com/questions/7488334/duplicate-records-created-by-find-or-create-in-railsmongoid
    # So we need to use explicit upserts at the Ruby-driver level to avoid race conditions and duplicate records!!!
    # Mongoid 3.0's find_and_modify, however will be atomic and also supports an upsert option, which is what we want
    user_params = {uid: params[:uid].to_s, provider: 'facebook'}
    user_params_with_name_and_image = user_params.merge(User.name_and_image_params_unless_blank(params))
    User.collection.update(user_params, {:$set => user_params_with_name_and_image}, upsert: true)
    user = User.where(user_params).first

    fp_params = user_params_with_name_and_image.except(:provider).merge(user_id: user.id)
    FacebookProfile.collection.update({user_id: user.id}, {:$set => fp_params}, upsert: true)
    [user, user.facebook_profile]
  end

  private

  def self.name_and_image_params_unless_blank(params)
    hash = {}
    hash[:name] = params[:name] unless params[:name].blank?
    hash[:image] = params[:image] unless params[:image].blank?
    hash
  end

end
