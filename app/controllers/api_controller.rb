class ApiController < ApplicationController

  before_filter :check_authorization
  skip_before_filter :verify_authenticity_token

  # DOCS: Always pass in a token, if available
  # Can pass in UID if no token -- API will tell you if we ran it once before already

  def trust_check
    @facebook_profile = FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(params.merge(fetching_directly: true))
    if @facebook_profile.valid? and !@facebook_profile.changed? # it was saved
      if @facebook_profile.has_scores?
        render 'score_ready'
      else
        # To run synchronously, just comment out the Resque line and uncomment the following one instead
        #FacebookFetcher.perform @facebook_profile.to_param, 'scoring', @facebook_profile.postback_url
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
  rescue Koala::Facebook::APIError => exception
    @facebook_profile.update_attribute(:facebook_api_error,exception.message) if @facebook_profile
    Rails.logger.tagged('api_controller', 'Facebook API Exception') {
      Rails.logger.error "Params: #{params.inspect}"
      Rails.logger.error exception.message
      Rails.logger.error exception.backtrace.join("\n")
    }
    render json: {errors: {token: [exception.message]}}, status: :unprocessable_entity
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
    if params[:app_id].blank? or params[:app_key].blank?
      errors = %w(app_id app_key).reduce({}) do |hash,attr|
        hash[attr] = ['must be provided'] if params[attr].blank?
        hash
      end
      response['WWW-Authenticate'] = %(api_key api_id tuple realm="api.trust.cc")
      render json: {errors: errors}, status: :unauthorized
    elsif Rails.env.development?
      ApiClient.setup_if_missing! params[:app_id]
    elsif !(auth_resp = ThreeScale.client.authorize(params.slice(:app_id,:app_key))).success?
      response['WWW-Authenticate'] = %(api_key api_id tuple realm="api.trust.cc")
      render json: {errors: {'base' => [%Q(Authorization failed! Code: #{auth_resp.error_code} "#{auth_resp.error_message}")]}},
             status: :unauthorized
    else
      # We're authorized
      # See if we have a known APIClient record
      ApiClient.setup_if_missing! params[:app_id]
    end
  end

end