class ScoringController < ApplicationController

  before_filter :not_for_production

  def new
    @user = User.new
  end

  def create
    # TODO: test for lookup only by UID, not by token, b/c token can be different over time for same user
    @user = User.find_or_initialize_by(uid: params[:user][:uid])
    @user.token = params[:user][:token]  # not mass-assignable
    if @user.new_record?
      @user.provider = 'facebook'
      @user.name = 'Yourself'
    end
    # save back in any case, to update token
    return render 'new' unless @user.save
    @facebook_profile = @user.facebook_profile
    @facebook_profile = @user.create_facebook_profile if @facebook_profile.nil?
    Resque.enqueue(FacebookFetcher, @user.to_param, 'scoring')
    redirect_to scoring_show_path(@facebook_profile.to_param)
  end

  def show
    @facebook_profile = FacebookProfile.find(params[:id])
  end

  private

  def not_for_production
    redirect_to root_path if Rails.env.production?
  end

end
