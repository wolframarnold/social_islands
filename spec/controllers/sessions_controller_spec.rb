require 'spec_helper'

describe SessionsController do

  context '#create' do
    before do
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:facebook]
    end

    it 'has flash[:notice]' do
      get :create, :provider => 'facebook'
      flash[:notice].should == 'Successfully logged in'
    end

    it 'redirects to facebook_profile_path' do
      get :create, :provider => 'facebook'
      response.should redirect_to(facebook_profile_path)
    end

    it 'should be signed_in' do
      get :create, :provider => 'facebook'
      controller.should be_signed_in
    end

    it 'sets current_user' do
      user = User.create!(uid: '123456790', provider: 'facebook')

      get :create, :provider => 'facebook'
      controller.current_user.should == user
    end

    it 'creates a user if not found' do
      expect {
        get :create, :provider => 'facebook'
      }.to change(User,:count).by(1)
    end

    it 'does not create a user if one exists' do
      User.create!(uid: '123456790', provider: 'facebook')

      expect {
        get :create, :provider => 'facebook'
      }.to_not change(User,:count)
    end

    it 'sets user_id in session' do
      user = User.create!(uid: '123456790', provider: 'facebook')

      get :create, :provider => 'facebook'
      session[:user_id].should == user.id.to_s
    end


  end

  context '#failure' do
    before do
      get :failure
    end

    it 'has flash[:error]' do
      flash[:error].should == 'Authentication failure'
    end

    it 'redirects to root_path' do
      response.should redirect_to(root_path)
    end
  end

  context '#destroy' do

    it 'deletes session' do
      session[:user_id] = 'some user_id'
      expect {
        get :destroy
      }.to change{session[:user_id]}.from('some user_id').to(nil)
    end

    it 'redirects to root_path' do
      get :destroy
      response.should redirect_to(root_path)
    end
  end
end
