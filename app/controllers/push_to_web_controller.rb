class PushToWebController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def socket
    socket = ESHQ.open(:channel => params[:channel])
    render :json => {:socket => socket}
  end

  def graph_ready
    ESHQ.send(channel: 'graph_ready_'+Digest::SHA1.hexdigest(params[:facebook_profile_id]), data: 'graph_ready', type: 'message')
    head 200
  end

end
