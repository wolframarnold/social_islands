class FacebookFetcher
  @queue = :fb_fetcher

  # user_id is the user'id ObjectID (as string) in Mongo
  # computation is "viz" or "scoring"
  def self.perform(user_id, computation)
    facebook_profile = FacebookProfile.where(user_id: user_id).first

    if !facebook_profile.has_edges?
      Rails.logger.tagged('fb_fetcher', "User#_id=#{user_id}") { Rails.logger.info "Retrieving FB Profile's nodes and edges for" }
      facebook_profile.get_nodes_and_edges
      facebook_profile.save!
    end

    if !facebook_profile.has_graph?
      # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
      # cannot handle hashes.
      Rails.logger.tagged('fb_fetcher', "User#_id=#{user_id}") { Rails.logger.info "Enqueuing '#{computation}' job" }
      Resque.push(computation,
                  class: "com.socialislands.viz.#{computation.camelize}Worker",
                  args: [user_id])
    end
  end

end