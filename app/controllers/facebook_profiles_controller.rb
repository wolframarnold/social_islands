class FacebookProfilesController < ApplicationController

  before_filter :authenticate!, except: :login

  def login
    return redirect_to(facebook_profile_path) if signed_in?
  end

  def show
    # Note: Job will be a no-op if fetch already occurred and graph exists,
    # otherwise it does what's necessary
    @has_graph = current_facebook_profile.has_graph?

    # Hack for dev environment: run direct w/o resque queue for easier setup and debugging
    if Rails.env.development?
      FacebookFetcher.perform(current_facebook_profile.to_param, 'viz', push_to_web_graph_ready_url)
    else
      Resque.enqueue(FacebookFetcher, current_facebook_profile.to_param, 'viz', push_to_web_graph_ready_url)
    end
  end

  def graph
    render :text => FacebookGraph.where(facebook_profile_id: current_facebook_profile.id).first.gexf, :content_type => 'application/gexf+xml', :layout => false
  end

  def label
    # label attr's come in as nested attr's, like label: { '1' => {name: 'abc', group_index: 123}, ...}
    # this code is currently handling only one
    labels_params = params[:label].first[1]  # get the label hash, i.e. {name: 'abc', group_index: 123}
    group_index = labels_params.delete(:group_index).to_i
    graph = current_facebook_profile.facebook_graph
    return head 404 if graph.nil?
    label = graph.labels.find_or_initialize_by(group_index: group_index)
    label.attributes = labels_params
    graph.save
    head 200
  end

end
