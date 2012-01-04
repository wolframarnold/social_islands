class ServicesController < ApplicationController

  before_filter :authenticate!

  def linkedin
    client = LinkedIn::Client.new
    client.authorize_from_access(current_user.token,current_user.secret)

  end

  def facebook
  end

end
