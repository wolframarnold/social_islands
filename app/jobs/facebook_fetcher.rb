class FacebookFetcher
  @queue = :fb_fetcher

  # user_id is the user'id ObjectID (as string) in Mongo
  # computation is "viz" or "scoring"
  def self.perform(user_id, computation, postback_url=nil)
    facebook_profile = FacebookProfile.where(user_id: user_id).first

    if !facebook_profile.has_edges?
      Rails.logger.tagged('fb_fetcher', "User#_id=#{user_id}") { Rails.logger.info "Retrieving FB Profile's nodes and edges for" }
      facebook_profile.get_profile_and_network_graph!
    end

    if !facebook_profile.has_graph?
      # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
      # cannot handle hashes.
      Rails.logger.tagged('fb_fetcher', "User#_id=#{user_id}") { Rails.logger.info "Enqueuing '#{computation}' job, postback url: '#{postback_url}'" }
      args = [user_id]
      args << postback_url if postback_url.present?
      Resque.push(computation,
                  class: "com.socialislands.viz.#{computation.camelize}Worker",
                  args: args)
    end
  end

end