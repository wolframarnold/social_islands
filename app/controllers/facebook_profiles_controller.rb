class FacebookProfilesController < ApplicationController

  before_filter :authenticate!, except: :login

  def login
    return redirect_to(facebook_profile_path) if signed_in?
  end

  def show
    # Note: Job will be a no-op if fetch already occurred and graph exists,
    # otherwise it does what's necessary
    @has_graph = current_facebook_profile.facebook_graph.count !=0

    # Hack for dev environment: run direct w/o resque queue for easier setup and debugging
    if Rails.env.development?
      FacebookFetcher.perform(current_facebook_profile.to_param, 'viz')
    else
      Resque.enqueue(FacebookFetcher, current_facebook_profile.to_param, 'viz')
    end
  end

  def graph
    # current_facebook_profile.facebook_profile.only(:graph) is not supported by Mongoid...
    render :text => FacebookProfile.graph_only.where(user_id: current_facebook_profile.id).first.graph, :content_type => 'application/gexf+xml', :layout => false
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

end
