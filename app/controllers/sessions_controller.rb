class SessionsController < ApplicationController

  def create
    omni = request.env['omniauth.auth']

    if omni['uid'].blank? || omni['provider'].blank?
      # Ward off robots, etc, that may be hitting this url with get requests
      redirect_to auth_failure_path
    else
      flash[:notice] = "Successfully logged in"

      user = User.where(provider: omni['provider'], uid: omni['uid']).first
      if user.nil?
        user = User.create!(provider: omni['provider'], uid: omni['uid'], image: omni['info']['image'], name: omni['info']['name'],
                            token: omni['credentials']['token'], secret: omni['credentials']['secret'])
      else
        # TODO: Possibly not a good idea to store the token and secret here -- is this vulnerable?
        user.token = omni['credentials']['token']
        user.secret = omni['credentials']['secret']
        user.save!
      end

      # TODO: Secure this with fingerprint or use Devise
      session[:user_id] = user.id.to_s
      redirect_to send("#{omni['provider']}_path")
    end
  end

  def failure
    flash[:error] = "Authentication failure"
    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end

end
