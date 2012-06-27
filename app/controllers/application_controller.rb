class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def signed_in?
    session[:facebook_profile_id] = params[:facebook_profile_id] if params[:facebook_profile_id] && Rails.env.development?
    session[:facebook_profile_id].present?
  end
  helper_method :signed_in?

  def current_facebook_profile
    FacebookProfile.find(session[:facebook_profile_id])
  end
  helper_method :current_facebook_profile

  def authenticate!
    redirect_to root_path unless signed_in?
  end

end
