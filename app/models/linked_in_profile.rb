require 'pp'

class LinkedInProfile

  include Mongoid::Document

  FIELDS = %w[first-name last-name headline location industry
              current-status current-share num-connections num-connections-capped
              summary specialties interests positions educations
              num-recommenders phone-numbers twitter-accounts im-accounts date-of-birth
              main-address member-url-resources picture-url api-standard-profile-request]


  def self.format_response(data)
    pp data
    nil
  end

end
