class Dashboard::UsersController < Dashboard::BaseController

  before_filter :not_for_production

  def index
    @facebook_profiles = FacebookProfile.dashboard_index(current_api_client.app_id).paginate(page: params[:page], per_page: 30)
  end

  #def search
  #  @query = Query.new(params[:query])
  #  @users = @query.run_on(User)
  #  render 'index'
  #end

  def show
    @facebook_profile = FacebookProfile.where(_id: params[:id], app_id: current_api_client.app_id).first
    return redirect_to root_path, alert: 'Record not found!' if @facebook_profile.nil?
  end

  private

  def not_for_production
    redirect_to root_path if Rails.env.production?
  end

end