class FacebookProfilesController < ApplicationController

  before_filter :authenticate!, except: :login
  before_filter :load_fb_profile, only: [:show, :label]

  def login
    return redirect_to(facebook_profile_path) if signed_in?
  end

  def show
    if @facebook_profile.nil?
      @facebook_profile = current_user.build_facebook_profile
      @facebook_profile.get_nodes_and_edges
      @facebook_profile.save!

      # NOTE: The args parameters MUST be AN ARRAY, for Jesque to pick it up correctly. It apparently
      # cannot handle hashes.
      Resque.push('viz', :class => 'com.socialislands.viz.VizWorker', :args => [current_user.to_param])
    end
  end

  def graph
    # current_user.facebook_profile.only(:graph) is not supported by Mongoid...
    render :text => FacebookProfile.graph_only.where(user_id: current_user.id).first.graph, :content_type => 'application/gexf+xml', :layout => false
  end

  def label
    # label attr's come in as nested attr's, like label: { '1' => {name: 'abc', group_index: 123}, ...}
    # this code is currently handling only one
    labels_params = params[:label].first[1]  # get the label hash, i.e. {name: 'abc', group_index: 123}
    group_index = labels_params.delete(:group_index).to_i
    label = @facebook_profile.labels.find_or_initialize_by(group_index: group_index)
    label.attributes = labels_params
    @facebook_profile.save
    head 200
    #render json: {error: "miserable failure"}, status: 500
  end


  private

  def load_fb_profile
    @facebook_profile = current_user.facebook_profile
  end
end
