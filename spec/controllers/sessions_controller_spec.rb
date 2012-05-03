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
      get :create, :provider => 'facebook'
      user = controller.current_user
      user.should be_kind_of(User)
      user.uid.should == OmniAuth.mock_auth_for(:facebook)[:uid]
      user.name.should == OmniAuth.mock_auth_for(:facebook)[:info][:name]
      user.image.should == OmniAuth.mock_auth_for(:facebook)[:info][:image]
      user.token.should == OmniAuth.mock_auth_for(:facebook)[:credentials][:token]
      user.secret.should == OmniAuth.mock_auth_for(:facebook)[:credentials][:secret]
    end

    it 'creates a user if not found' do
      expect {
        get :create, :provider => 'facebook'
      }.to change(User,:count).by(1)
    end

    it 'does not create a user if one exists' do
      FactoryGirl.create(:fb_user, uid: OmniAuth.mock_auth_for(:facebook)[:uid])

      expect {
        get :create, :provider => 'facebook'
      }.to_not change(User,:count)
    end

    it 'sets user_id in session' do
      user = FactoryGirl.create(:fb_user, uid: OmniAuth.mock_auth_for(:facebook)[:uid])

      get :create, :provider => 'facebook'
      session[:user_id].should == user.to_param
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
