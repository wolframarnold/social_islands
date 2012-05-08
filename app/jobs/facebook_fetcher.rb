class FacebookFetcher
  @queue = :fb_fetcher

  # user_id is the user'id ObjectID (as string) in Mongo
  # computation is "viz" or "scoring"
  def self.perform(user_id, computation)
    facebook_profile = FacebookProfile.where(user_id: user_id).first

    if !facebook_profile.has_edges?
      facebook_profile.get_nodes_and_edges
      facebook_profile.save!
    end

    if !facebook_profile.has_graph?
      # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
      # cannot handle hashes.
      Resque.push(computation,
                  class: "com.socialislands.viz.#{computation.camelize}Worker",
                  args: [user_id])
    end
  end

end