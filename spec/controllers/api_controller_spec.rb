require 'spec_helper'

describe ApiController do

  before do
    request.accept = Mime::JSON
  end

  # /score with user: {uid, token, email (opt)}, postback_url, api_key

  context 'known API Key' do
    let!(:api_client) { FactoryGirl.create(:api_client) }
    let(:post_params) { {user: {uid: '123456', token: 'abcdefghij'}, postback_url: "http://#{api_client.postback_domain}/trust_score", api_key: api_client.api_key } }

    context 'when postback_url' do
      it 'is missing, returns unprocessable entity with error' do
        post :create_profile, post_params.except(:postback_url)
        response.status.should == 422 # unprocessable
        JSON.parse(response.body).should == {'errors' => ['postback_url' => 'must be provided']}
      end

      it "does not match api_client's postback domain, returns unprocessable entity with error" do
        post :create_profile, post_params.merge(postback_url: 'http://some.other.url/score')
        response.status.should == 422 # unprocessable
        JSON.parse(response.body).should == {'errors' => ['postback_url' => "must match #{api_client.postback_domain}"]}
      end
    end

    context 'new user' do
      before do
        Resque.should_receive(:enqueue).with(FacebookFetcher, instance_of(String), 'scoring', post_params[:postback_url])
      end

      it 'creates a user entry uid, token' do
        expect {
          post :create_profile, post_params
          assigns(:user).should be_kind_of(User)
          assigns(:user).uid.should == '123456'
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

    context 'existing user' do
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

      it 'finds existing fb profile' do
        fb_profile = FactoryGirl.create(:facebook_profile, user: user)
        post :create_profile, post_params_existing_user
        assigns(:facebook_profile).should == fb_profile
      end
    end
  end

  context 'unknown API key' do
    it 'responds with 401 -- unauthorized' do
      post :create_profile
      response.status.should == 401
    end
  end

end