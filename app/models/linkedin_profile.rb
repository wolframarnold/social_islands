class LinkedinProfile

  include MongoMapper::Document

  belongs_to :user

  timestamps!

  FIELDS = %w[first-name last-name location
              phone-numbers twitter-accounts im-accounts date-of-birth
              main-address
              member-url-resources picture-url
              api-standard-profile-request site-standard-profile-request

              industry
              headline
              summary skills positions educations specialties interests
              associations

              num-connections num-connections-capped num-recommenders

              current-status current-share recommendations-received
             ]

  STRUCTURED_FIELDS = %w[positions educations skills recommendations-received
                         current_share date_of_birth associations
                         api_standard_profile_request location
                         member_url_resources phone_numbers twitter_accounts
  ]

  def fetch_profile
    client = LinkedIn::Client.new
    client.authorize_from_access(user.token,user.secret)

    client.profile(:fields => FIELDS)

  end

#
#
#  def self.format_response(data)
#    pp data
#    nil
#  end
#
end
