class FacebookFetcher
  @queue = :fb_fetcher

  # computation is "viz" or "scoring"
  def self.perform(facebook_profile_id, computation, postback_url=nil)
    facebook_profile = FacebookProfile.find(facebook_profile_id)

    if facebook_profile.last_fetched_at.nil?
      Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}") { Rails.logger.info "Retrieving Facebook profile and network" }
      facebook_profile.import_profile_and_network!
    end

    case computation
      when 'viz'
        # Don't re-generate graph if we already have it
        return if facebook_profile.has_graph?
        # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
        # cannot handle hashes.
        Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}") { Rails.logger.info "Enqueuing '#{computation}' job, postback url: '#{postback_url}'" }
        args = [facebook_profile_id]
        args << postback_url if postback_url.present?
        Resque.push(computation,
                    class: "com.socialislands.viz.#{computation.camelize}Worker",
                    args: args)

      when 'scoring'
        # Using local ruby core here, not enqueueing other job
        Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}") { Rails.logger.info "Computing scores" }
        facebook_profile.compute_trust_score
        if postback_url.present?
          Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}") { Rails.logger.info "Pinging postback url: #{postback_url}" }
          response = RestClient.post postback_url,
                          {uid: facebook_profile.uid,
                           profile_maturity: facebook_profile.profile_maturity,
                           trust_score: facebook_profile.trust_score }.to_json,
                           content_type: :json, accept: :json
        end

    end

  rescue => e
    Rails.logger.tagged('fb_fetcher', "FacebookProfile#_id=#{facebook_profile_id}", 'Exception') {
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    }
    raise
  end

end