class FacebookFetcher
  @queue = :fb_fetcher

  def self.perform(user_id)
    facebook_profile = FacebookProfile.where(user_id: user_id).first
    facebook_profile.get_nodes_and_edges
    facebook_profile.save!

    # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
    # cannot handle hashes.
    Resque.push('viz', :class => 'com.socialislands.viz.VizWorker', :args => [user_id])
  end

end