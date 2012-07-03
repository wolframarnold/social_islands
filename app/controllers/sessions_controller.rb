class SessionsController < ApplicationController

  def create
    omni = request.env['omniauth.auth']

    if omni['uid'].blank? || omni['provider'].blank? || omni['provider'] != 'facebook'
      # Ward off robots, etc, that may be hitting this url with get requests
      redirect_to auth_failure_path
    else
      flash[:notice] = "Successfully logged in"

      fp = FacebookProfile.find_or_create_by_uid_and_api_key profile_attributes_from_omni(omni)
      session[:facebook_profile_id] = fp.to_param
      redirect_to send("#{omni['provider']}_profile_path")
    end
  end

  def failure
    flash[:error] = "Authentication failure"
    redirect_to root_path
  end

  def destroy
    token = current_facebook_profile.token
    reset_session
    redirect_to facebook_sign_out_url(token)
  end

  private

  def profile_attributes_from_omni(omni)
    { uid: omni['uid'],
      api_key: SOCIAL_ISLANDS_TRUST_CC_API_KEY,
      token: omni['credentials']['token'],
      image: omni['info']['image'],
      name: omni['info']['name'],
      token_expires: omni['credentials']['expires']
    }.tap do |h|
      h[:token_expires_at] = Time.at(omni['credentials']['expires_at']) unless omni['credentials']['expires_at'].blank?
    end
  end

  def facebook_sign_out_url(token)
    "https://www.facebook.com/logout.php?next=#{root_url}&access_token=#{token}"
  end
end
