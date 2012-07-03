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

    it 'sets current_facebook_profile' do
      get :create, :provider => 'facebook'
      fp = controller.current_facebook_profile
      fp.should be_kind_of(FacebookProfile)
      fp.uid.should == OmniAuth.mock_auth_for(:facebook)[:uid].to_i
      fp.api_key.should == 'social_islands'
      fp.name.should == OmniAuth.mock_auth_for(:facebook)[:info][:name]
      fp.image.should == OmniAuth.mock_auth_for(:facebook)[:info][:image]
      fp.token.should == OmniAuth.mock_auth_for(:facebook)[:credentials][:token]
      fp.token_expires.should be_true
      fp.token_expires_at.should > 2.months.from_now
    end

    it 'does not create a FacebookProfile if one exists' do
      create(:wolf_facebook_profile, uid: OmniAuth.mock_auth_for(:facebook)[:uid], api_key: SOCIAL_ISLANDS_TRUST_CC_API_KEY)

      expect {
        get :create, :provider => 'facebook'
      }.to_not change(FacebookProfile,:count)
    end

    it 'sets facebook_profile_id in session' do
      fp = create(:wolf_facebook_profile, uid: OmniAuth.mock_auth_for(:facebook)[:uid], api_key: SOCIAL_ISLANDS_TRUST_CC_API_KEY)

      get :create, :provider => 'facebook'
      session[:facebook_profile_id].should == fp.to_param
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
    before do
      @fp = create(:wolf_facebook_profile)
      controller.stub(:current_facebook_profile).and_return(@fp)
      class << controller
        public :facebook_sign_out_url
      end
    end

    it 'deletes session' do
      session[:facebook_profile_id] = 'some fp_id'
      expect {
        get :destroy
      }.to change{session[:facebook_profile_id]}.from('some fp_id').to(nil)
    end

    it 'redirects to root_path' do
      get :destroy
      response.should redirect_to(controller.facebook_sign_out_url(@fp.token))
    end
  end
end
