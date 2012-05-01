class PushToWebController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def socket
    socket = ESHQ.open(:channel => params[:channel])
    render :json => {:socket => socket}
  end

  def graph_ready
    @facebook_profile = FacebookProfile.find(params[:facebook_profile_id])
    ESHQ.send(channel: 'graph_ready_'+Digest::SHA1.hexdigest(params[:facebook_profile_id]),
              data: {message: 'graph_ready',
                     # render returns an array -- why?
                     labels_html: render(partial: 'facebook_profiles/labels').first}.to_json,
              type: 'message')
    head 200
  end

end
