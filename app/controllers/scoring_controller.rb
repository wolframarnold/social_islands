#class ScoringController < ApplicationController
#
#  before_filter :not_for_production
#
#  def new
#    @user = User.new
#  end
#
#  def show
#    @facebook_profile = FacebookProfile.find(params[:id])
#  end
#
#  private
#
#  def not_for_production
#    redirect_to root_path if Rails.env.production?
#  end
#
#end
