class ServicesController < ApplicationController

  before_filter :authenticate!

  def linkedin
    @linkedin_profile = current_user.linkedin_profile
    if @linkedin_profile.nil?
      @linkedin_profile = current_user.build_linkedin_profile
      @linkedin_profile.fetch_profile
      @linkedin_profile.save!
    end
  end

  def facebook
    @facebook_profile = current_user.facebook_profile
    if @facebook_profile.nil?
      @facebook_profile = current_user.build_facebook_profile
      @facebook_profile.get_nodes_and_edges
      @facebook_profile.save!
    end
    #Resque.push('viz', :class => 'com.socialislands.viz.App', :args => {facebook_profile_id: @facebook_profile.id})
  end

  def facebook_edges
    @facebook_profile = current_user.facebook_profile
  end

end
