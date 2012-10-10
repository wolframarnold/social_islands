class Analytic::UsersController < Analytic::BaseController

  before_filter :not_for_production

  def index
    @facebook_profiles = FacebookProfile.analytic_index(current_api_client.app_id).paginate(page: params[:page], per_page: 30)
  end

  #def search
  #  @query = Query.new(params[:query])
  #  @users = @query.run_on(User)
  #  render 'index'
  #end

  def show
    #@facebook_profile = FacebookProfile.where(_id: params[:id], app_id: current_api_client.app_id).first
    #temporary remove app_id to display analytic
    @facebook_profile = FacebookProfile.where(_id: params[:id]).first
    return redirect_to root_path, alert: 'Record not found!' if @facebook_profile.nil?
    if @facebook_profile.computed_stats[:top_friends].blank?
      # This happens as part of the fetcher, but for old records we may not yet have it.
      @facebook_profile.compute_top_friends_stats
      @facebook_profile.save
      @facebook_profile.reload  # this is important to convert symbols in computed_stats to strings; otherwise we can't access by 'top_friends' by only :top_friends
    end
  end

  private

  def not_for_production
    redirect_to root_path if Rails.env.production?
  end

end