#require 'spec_helper'
#
#describe ScoringController do
#
#  describe "GET 'new'" do
#    it "returns http success and assigns @user" do
#      get :new
#      assigns(:user).should be_kind_of(User)
#      response.should be_success
#    end
#  end
#
#  describe "GET 'show'" do
#    let!(:facebook_profile) {FactoryGirl.create(:facebook_profile)}
#
#    it "assigns variable and returns http success" do
#      get :show, :id => facebook_profile.to_param
#      assigns(:facebook_profile).should be_kind_of(FacebookProfile)
#      response.should be_success
#    end
#  end
#
#end
