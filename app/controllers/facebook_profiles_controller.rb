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
      Resque.push('viz', :class => 'com.socialislands.viz.VizWorker', :args => [current_user.id])
    end
  end

  def graph
    render :text => current_user.facebook_profile.graph, :content_type => 'application/gexf+xml', :layout => false
  end

  def label
    labels_params = params[:label]
    # TODO: Refactor to use Mongoid adapter which natively supports searching embedded docs
    # as well as a find_or_create_by method which is useful for embedded docs
    # MongoMapper also doesn't appear to store the embedded object ID even though it assigns one
    labels = @facebook_profile.labels

    labels.each_with_index do |label,idx|
      label_params = labels_params[label.group_index.to_s]
      if label_params.present?
        labels[idx].name = label_params[:name]
      end
    end
    # TODO: We should be able to use the $set method to just update labels, but it doesn't work with MongoMoapper
    @facebook_profile.save
    head 200
    #render json: {error: "miserable failure"}, status: 500
  end


  private

  def load_fb_profile
    @facebook_profile = current_user.facebook_profile
  end
end
