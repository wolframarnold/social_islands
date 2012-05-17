require 'spec_helper'

describe ApiController do

  before do
    request.accept = Mime::JSON
  end

  context 'known API Key' do
    let!(:api_client) { FactoryGirl.create(:api_client) }
    let(:post_params) { {user: {uid: '333333', token: 'abcdefghij'}, postback_url: "http://#{api_client.postback_domain}/trust_score", api_key: api_client.api_key } }

    context 'POST /profile -- new user' do
      before do
        Resque.should_receive(:enqueue).with(FacebookFetcher, instance_of(String), 'scoring', post_params[:postback_url])
      end

      it 'sends accepted header' do
        post :create_profile, post_params
        response.status.should == 202
      end

      it 'creates a user entry uid, token' do
        expect {
          post :create_profile, post_params
          assigns(:user).should be_kind_of(User)
          assigns(:user).uid.should == '333333'
          assigns(:user).token.should == 'abcdefghij'
        }.to change(User,:count).by(1)
      end

      it 'creates a user entry pointing to API client, and vice versa' do
        expect {
          post :create_profile, post_params
          assigns(:user).api_clients.should == [api_client]
        }.to change{api_client.reload.user_ids.length}.by(1)
        api_client.user_ids.should == [assigns(:user).id]
      end

      it 'creates a new FB profile' do
        expect {
          post :create_profile, post_params
        }.to change(FacebookProfile,:count).by(1)
      end
    end

    context 'with non-matching postback url' do
      it 'enqueues blank URL' do
        Resque.should_receive(:enqueue).with(FacebookFetcher, instance_of(String), 'scoring', '')
        post :create_profile, post_params.merge(postback_url: 'http://some.random.other.url.com')
      end
    end

    context 'POST /profile -- existing user' do
      let!(:user) { FactoryGirl.create(:fb_user) }
      let(:post_params_existing_user) { new_params = post_params; new_params[:user][:uid] = user.uid; new_params }

      before do
        Resque.should_receive(:enqueue).with(FacebookFetcher, user.to_param, 'scoring', post_params[:postback_url])
      end

      it 'refreshes token' do
        expect {
          post :create_profile, post_params_existing_user
        }.to change{user.reload.token}.from('BCDEFG').to('abcdefghij')
      end

      it 'associates api_client' do
        expect {
          post :create_profile, post_params_existing_user
        }.to change{api_client.reload.user_ids}.from([]).to([user.id])
      end

      it 'will not associate api_client more than once' do
        user.api_clients << api_client
        expect {
          post :create_profile, post_params_existing_user
        }.not_to change{user.reload.api_client_ids.length}
      end

      it 'finds existing fb profile' do
        fb_profile = FactoryGirl.create(:facebook_profile, user: user)
        post :create_profile, post_params_existing_user
        assigns(:facebook_profile).should == fb_profile
      end
    end

    context 'GET /score -- non-existent user' do
      it 'returns 404' do
        get :score, user: {uid: '444444' }, api_key: api_client.api_key
        response.status.should == 404
      end
    end

    context 'GET /score -- existing user' do
      let!(:user) { FactoryGirl.create(:facebook_profile).user }

      it 'is successful' do
        api_client.users << user
        get :score, user: {uid: user.uid }, api_key: api_client.api_key
        response.should be_success
      end

      it 'is denied if attempting to access user with other API credentials' do
        get :score, user: {uid: user.uid }, api_key: api_client.api_key
        response.status.should == 401
      end
    end

  end

  context 'unknown API key' do
    it 'POST responds with 401 -- unauthorized' do
      post :create_profile
      response.status.should == 401
    end

    it 'GET responds with 401 -- unauthorized' do
      get :score, user: {uid: '123456'}, api_key: 'abcdefg'
      response.status.should == 401
    end
  end

end