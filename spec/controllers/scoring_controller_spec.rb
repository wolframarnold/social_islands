require 'spec_helper'

describe ScoringController do

  describe "GET 'new'" do
    it "returns http success and assigns @user" do
      get :new
      assigns(:user).should be_kind_of(User)
      response.should be_success
    end
  end

  describe "POST 'create'" do
    before do
      #Resque.enqueue(FacebookFetcher, current_user.to_param)
      Resque.should_receive(:enqueue).with FacebookFetcher, anything, 'scoring'
    end
    context "when profile doesn't exist" do

      context 'when user exists' do
        let(:user) {FactoryGirl.create(:fb_user)}
        it 'saves token' do
          expect {
            post :create, user: {uid: user.uid, token: 'abc123_new'}
          }.to change{user.reload.token}.from('BCDEFG').to('abc123_new')
        end
      end
      context "when user doesn't exist" do
        it 'creates a new user with uid and token' do
          expect {
            post :create, user: {uid: '987654321', token: 'abc123_new'}
            assigns(:user).should_not be_nil
            assigns(:user).uid.should == '987654321'
            assigns(:user).token.should == 'abc123_new'
          }.to change(User,:count).by(1)
        end
        it 'creates a new FB profile' do
          expect {
            post :create, user: {uid: '987654321', token: 'abc123_new'}
          }.to change(FacebookProfile, :count).by(1)
        end
      end
    end
  end

  describe "GET 'show'" do
    let!(:facebook_profile) {FactoryGirl.create(:facebook_profile)}

    it "assigns variable and returns http success" do
      get :show, :id => facebook_profile.to_param
      assigns(:facebook_profile).should be_kind_of(FacebookProfile)
      response.should be_success
    end
  end

end
