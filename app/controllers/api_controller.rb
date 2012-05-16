class ApiController < ApplicationController

  before_filter :check_authorization

  def create_profile
    postback_url = params[:postback_url]

    @user = User.find_or_initialize_by(uid: params[:user][:uid])
    @user.token = params[:user][:token]  # not mass-assignable
    @user.provider = 'facebook' if @user.new_record?
    @user.api_clients << @api_client unless @user.api_client_ids.include?(@api_client.id)
    if !@user.save
      return render(:json => {:errors => @user.errors.to_json}, status: :unprocessable_entity)
    end
                                         # save back in any case, to update token
    @facebook_profile = @user.facebook_profile
    @facebook_profile = @user.create_facebook_profile if @facebook_profile.nil?

    # TODO: move this to a Job model with validation,etc.
    Resque.enqueue(FacebookFetcher, @user.to_param, 'scoring', postback_domain_matches?(postback_url) ? postback_url : '')

    head :accepted
  end

  #def update_profile
  #
  #end

  # user[uid], api_key
  def score
    @facebook_profile = FacebookProfile.where(uid: params[:user][:uid]).first
    if @facebook_profile.nil?
      head 404 # not_found
    else
      render :json => @facebook_profile
    end
  end

  #def graph
  #
  #end

  private

  def check_authorization
    head :unauthorized if params[:api_key].blank? || (@api_client = ApiClient.where(api_key: params[:api_key]).first).nil?
  end

  def postback_domain_matches?(url)
    url =~ %r{^https?://#{@api_client.postback_domain}}
  end
end