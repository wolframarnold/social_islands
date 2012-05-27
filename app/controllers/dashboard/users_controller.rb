class Dashboard::UsersController < Dashboard::BaseController

  before_filter :not_for_production

  def index
    @users = User.order_by([:created_at, :desc]).paginate(page: params[:page], per_page: 30)
  end

  def search
    @query = Query.new(params[:query])
    @users = @query.run_on(User)
    render 'index'
  end

  private

  def not_for_production
    redirect_to root_path if Rails.env.production?
  end

end