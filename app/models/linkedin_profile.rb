class LinkedinProfile

  include MongoMapper::Document

  belongs_to :user

  timestamps!

  PERSONAL_FIELDS = %w[ first-name last-name location
                        phone-numbers twitter-accounts im-accounts date-of-birth
                        main-address
                        member-url-resources picture-url
                        api-standard-profile-request site-standard-profile-request
                      ]

  PROFESSIONAL_FIELDS = %w[ industry
                            headline
                            summary skills positions educations specialties interests
                            associations
                          ]

  SOCIAL_FIELDS = %w[num-connections num-connections-capped num-recommenders
                     current-share recommendations-received]

  FIELDS = PERSONAL_FIELDS + PROFESSIONAL_FIELDS + SOCIAL_FIELDS

  STRUCTURED_FIELDS = %w[positions educations skills recommendations-received
                         current_share date_of_birth associations
                         api_standard_profile_request location
                         member_url_resources phone_numbers twitter_accounts
  ]

  def fetch_profile
    assign_attribute_hash @li_client.profile(:fields => FIELDS)
  end

  def assign_attribute_hash mash
    mash.each_pair do |key,val|
      if key == 'associations'
        self['professional_associations'] = val # associations is a name clash with a native method of MongoMapper objects
      else
        self[key] = val
      end
    end
  end

  def completeness
    total = FIELDS.size
    actual = FIELDS.count {|field| attr = field.underscore; self.respond_to?(attr) && self.send(attr).present? }
    (actual * 100) / total
  end

  def li_client
    @li_client ||= LinkedIn::Client.new.tap {|c| c.authorize_from_access(user.token,user.secret) }
  end

end

