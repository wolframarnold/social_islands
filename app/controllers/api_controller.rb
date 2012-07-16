class ApiController < ApplicationController

  before_filter :check_authorization
  skip_before_filter :verify_authenticity_token

  # TODO: Use single API endpoint /profile
  # - use it to update token, postback url
  # - it'll return score if known right away, or else makes a postback call

  # DOCS: Always pass in a token, if available
  # Can pass in UID if no token -- API will tell you if we ran it once before already

  def trust_check
    @facebook_profile = FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(params)
    if @facebook_profile.valid? and !@facebook_profile.changed? # it was saved
      if @facebook_profile.has_scores?
        render 'score_ready'
      else
        Resque.enqueue(FacebookFetcher, @facebook_profile.to_param, 'scoring', @facebook_profile.postback_url)
        render 'score_not_ready', status: :accepted
      end
    else
      if @facebook_profile.errors[:token].present?
        # this happens when trying to look up a record by facebook_id w/o token --> it fails creating a new record due to missing token
        # means the record wasn't found
        head :not_found
      else
        # typically postback_url errors
        render json: {errors: @facebook_profile.errors}, status: :unprocessable_entity
      end
    end
  rescue ArgumentError => e
    render json: {errors: {base: [e.message]}}, status: :unprocessable_entity
  end


  # Other stuff
  #def drill_down
  #
  #end
#
#  #def graph
#  #
#  #end
#
  private

  def check_authorization
    if params[:app_id].blank? || !ApiClient.where(app_id: params[:app_id]).exists?
      render json: {errors: {'app_id' => 'is missing or has no access privileges for this record'}},
             status: :forbidden
    end
  end

end