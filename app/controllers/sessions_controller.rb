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
        user = User.new(provider: omni['provider'], uid: omni['uid'], image: omni['info']['image'], name: omni['info']['name'])
        set_credentials(user,omni['credentials'])
        user.save!
      else
        # TODO: Possibly not a good idea to store the token and secret here -- is this vulnerable?
        set_credentials(user,omni['credentials'])
        user.save!
      end

      # TODO: Is the session automatically secure with a fingerprint digest? I think so, but need to double check
      session[:user_id] = user.to_param
      redirect_to send("#{omni['provider']}_profile_path")
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

  private

  def set_credentials(user,omni_credentials)
    user.token = omni_credentials['token']
    user.secret = omni_credentials['secret']
    user.expires_at = Time.at(omni_credentials['expires_at'])
    user.expires = omni_credentials['expires']
  end

end
