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

      # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
      # cannot handle hashes.
      Resque.push('viz', :class => 'com.socialislands.viz.VizWorker', :args => [current_user.id])
    end
  end

  def facebook_edges
    @facebook_profile = current_user.facebook_profile
  end

  def facebook_graph
    render :text => current_user.facebook_profile.graph, :content_type => 'application/gexf+xml', :layout => false
  end

  def facebook_label
    @facebook_profile = current_user.facebook_profile
    labels = @facebook_profile.labels
    labels[params[:groupId]] = params[:labelText]
    if @facebook_profile.save
      head 200
    else
      head 500
    end
  end

end
