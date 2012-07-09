class ApiController < ApplicationController

  before_filter :check_authorization

  def create_or_update_profile
    @facebook_profile = FacebookProfile.find_or_create_by_token_and_api_key(params)
    Resque.enqueue(FacebookFetcher, @facebook_profile.to_param, 'scoring')
    head 201

  rescue ArgumentError => e
    render json: {errors: [e.message]}, status: :unprocessable_entity
  end

  def score
    @facebook_profile = FacebookProfile.where(uid: params[:facebook_profile_id]).first
    if @facebook_profile.nil?
      head :not_found
    else
      return head :forbidden if @facebook_profile.api_key != params[:api_key]
      if @facebook_profile.profile_authenticity.present?
        render :score_ready  # Status 200 -- "OK"
      else
        if params[:postback_url].present?
          @facebook_profile.postback_url = params[:postback_url]
          return render(json: {errors: @facebook_profile.errors}, status: :unprocessable_entity) unless @facebook_profile.save
        end
        Resque.enqueue(FacebookFetcher, @facebook_profile.to_param, 'scoring', @facebook_profile.postback_url)
        render :score_not_ready, :status => 202  # "Accepted"
      end

    end
  end
#
#  #def graph
#  #
#  #end
#
  private

  def check_authorization
    if params[:api_key].blank? || !ApiClient.where(api_key: params[:api_key]).exists?
      render json: {errors: {'api_key' => 'is missing or has no access privileges for this record'}},
             status: :forbidden
    end
  end

end