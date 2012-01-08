class ServicesController < ApplicationController

  before_filter :authenticate!

  def linkedin
    @linkedin_profile = current_user.linkedin_profile
    if @linkedin_profile.nil?
      @linkedin_profile = current_user.linkedin_profile.build
      @linkedin_profile.fetch_profile
    end
  end

  def facebook
  end

end
