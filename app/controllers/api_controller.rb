class ApiController < ApplicationController
#
#  before_filter :check_authorization
#
#  def create_profile
#    @facebook_profile = FacebookProfile.find_or_create_by_token_and_api_key(params[:token], params[:api_key])
#    @user = @facebook_profile.user
#    if @user.new_record?
#      respond_to do |fmt|
#        fmt.json { render(:json => {:errors => @user.errors.to_json}, status: :unprocessable_entity) }
#        fmt.html { render 'scoring/new' }
#      end
#    else
#      @user.api_clients << @api_client if @user.new_record? || !@user.api_client_ids.include?(@api_client.id)
#
#      postback_url = params[:postback_url]
#
#      # Debugging note:
#      # You can call FacebookFetcher.perform here directly to run this synchronously which
#      # may be easier for debugging.
#      #FacebookFetcher.perform(@user.to_param, 'scoring', postback_domain_matches?(postback_url) ? postback_url : '')
#      Resque.enqueue(FacebookFetcher, @user.to_param, 'scoring', postback_domain_matches?(postback_url) ? postback_url : '')
#
#      respond_to do |fmt|
#        fmt.json { head :accepted }
#        fmt.html { redirect_to scoring_show_path(@facebook_profile.to_param),
#                   flash: {notice: 'Please reload when score is ready.'}
#        }
#      end
#    end
#  rescue Koala::Facebook::APIError => exception
#    respond_to do |fmt|
#      fmt.json { render status: :unprocessable_entity, json: {:errors => exception.message} }
#      fmt.html { redirect_to scoring_new_path, flash: {alert: exception.message }}
#    end
#  end
#
#  def score
#    uid = params[:uid]
#    @facebook_profile = FacebookProfile.where(uid: params[:uid]).first
#    if @facebook_profile.nil?
#      head :not_found # not_found
#    else
#      # TODO: use associations for this
#      return head :unauthorized unless @api_client.user_ids.include?(@facebook_profile.user_id)
#    end
#  end
#
#  #def graph
#  #
#  #end
#
#  private
#
#  def check_authorization
#    head :unauthorized if params[:api_key].blank? || (@api_client = ApiClient.where(api_key: params[:api_key]).first).nil?
#  end
#
#  def postback_domain_matches?(url)
#    url =~ %r{^https?://#{@api_client.postback_domain}}
#  end
end