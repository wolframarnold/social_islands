class ServicesController < ApplicationController

  before_filter :authenticate!

  def linkedin
    @linkedin_profile = current_user.linkedin_profile
    if @linkedin_profile.nil?
      @linkedin_profile = current_user.build_linkedin_profile
      @linkedin_profile.fetch_profile
      @linkedin_profile.save!
    end
  end

  def facebook
  end

end
