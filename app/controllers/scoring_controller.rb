class ScoringController < ApplicationController

  before_filter :not_for_production

  def new
    @user = User.new
  end

  def create
    @user = User.find_or_initialize_by(params[:user])
    if @user.new_record?
      @user.provider = 'facebook'
      @user.name = 'Yourself'
      return render 'new' unless @user.save
    end
    @facebook_profile = @user.facebook_profile
    if @facebook_profile.nil?
      @facebook_profile = @user.create_facebook_profile
      @facebook_profile.get_nodes_and_edges
      @facebook_profile.save!
      Resque.push('scoring', :class => 'com.socialislands.viz.ScoringWorker', :args => [@user.to_param])
    end
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
