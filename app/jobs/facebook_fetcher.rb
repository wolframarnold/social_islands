class FacebookFetcher
  @queue = :fb_fetcher

  # computation is "viz" or "scoring"
  def self.perform(facebook_profile_id, computation, postback_url=nil, postback_customer_id=nil)
    facebook_profile = FacebookProfile.find(facebook_profile_id)

    Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}", "FacebookUID=#{facebook_profile.uid}") do
      # TODO: Refetch in all cases, but make provisions for not over-writing existing graph/score
      if facebook_profile.should_fetch?
        Rails.logger.info "Retrieving Facebook profile and network"
        facebook_profile.import_profile_and_network!
      end

      case computation
        when 'viz'
          # Don't re-generate graph if we already have it
          return if facebook_profile.has_graph?
          # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
          # cannot handle hashes.
          Rails.logger.info "Enqueuing '#{computation}' job, postback url: '#{postback_url}'"
          args = [facebook_profile_id]
          args << postback_url if postback_url.present?
          Resque.push(computation,
                      class: "com.socialislands.viz.#{computation.camelize}Worker",
                      args: args)

        when 'scoring'
          # Using local ruby core here, not enqueueing other job
          Rails.logger.info "Computing scores"}
          facebook_profile.compute_all_scores!
          if postback_url.present?
            Rails.logger.info "Pinging postback url: #{postback_url}"
            RestClient.post postback_url,
                            {name: facebook_profile.name,
                             image: facebook_profile.image,
                             facebook_id: facebook_profile.uid,
                             profile_authenticity: facebook_profile.profile_authenticity,
                             trust_score: facebook_profile.trust_score}.to_json,
                            content_type: :json, accept: :json
          end

      end
    end

  rescue Koala::Facebook::APIError => exception
    facebook_profile.update_attribute(:facebook_api_error, exception.message)
    Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}", "FacebookUID=#{facebook_profile.uid}", 'Facebook API Exception') {
      Rails.logger.error exception.message
      Rails.logger.error exception.backtrace.join("\n")
    }
    if computation != 'viz' && postback_url.present? # The postback mechanism doesn't work for social islands
      RestClient.post postback_url,
                      {errors: {base: ["Facebook API Error--#{exception.message}"]}}.to_json,
                      content_type: :json, accept: :json
    end
  rescue => e
    Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}", "FacebookUID=#{facebook_profile.uid}", 'Exception') {
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    }
    raise
  end

end