class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def signed_in?
    session[:user_id] = params[:user_id] if params[:user_id] && Rails.env.development?
    session[:user_id].present?
  end
  helper_method :signed_in?

  def current_user
    User.find(session[:user_id])
  end
  helper_method :current_user

  def authenticate!
    redirect_to root_path unless signed_in?
  end

end
