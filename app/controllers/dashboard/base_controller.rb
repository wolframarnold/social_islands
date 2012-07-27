class Dashboard::BaseController < ApplicationController
  layout 'dashboard'

  def current_api_client
    ApiClient.where(app_id: 'localhost_app_id').first
  end

end