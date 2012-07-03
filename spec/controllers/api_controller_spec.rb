#require 'spec_helper'
#
#describe ApiController do
#
#  render_views
#
#  before do
#    request.accept = Mime::JSON
#  end
#
#  context 'known API Key' do
#    let!(:api_client) { FactoryGirl.create(:api_client) }
#    let(:post_params) { { token: 'abcdefghij', postback_url: "http://#{api_client.postback_domain}/trust_score", api_key: api_client.api_key } }
#
#    context 'POST /profile -- new profile' do
#      before do
#        Koala::Facebook::API.any_instance.should_receive(:get_object).and_return('id'=>'7654321')
#        Resque.should_receive(:enqueue).with(FacebookFetcher, instance_of(String), 'scoring', post_params[:postback_url])
#      end
#
#      it 'sends accepted header' do
#        post :create_profile, post_params
#        response.status.should == 202
#      end
#
#      it 'creates a user entry uid, token' do
#        expect {
#          post :create_profile, post_params
#          assigns(:user).should be_kind_of(User)
#          assigns(:user).uid.should == '7654321'
#          assigns(:user).token.should == 'abcdefghij'
#        }.to change(User,:count).by(1)
#      end
#
#      it 'creates a user entry pointing to API client, and vice versa' do
#        expect {
#          post :create_profile, post_params
#          assigns(:user).api_clients.should == [api_client]
#        }.to change{api_client.reload.user_ids.length}.by(1)
#        api_client.user_ids.should == [assigns(:user).id]
#      end
#
#      it 'creates a new FB profile' do
#        expect {
#          post :create_profile, post_params
#        }.to change(FacebookProfile,:count).by(1)
#      end
#    end
#
#    context 'POST /profile with non-matching postback url' do
#      it 'enqueues blank URL' do
#        Koala::Facebook::API.any_instance.should_receive(:get_object).and_return('id'=>'7654321')
#        Resque.should_receive(:enqueue).with(FacebookFetcher, instance_of(String), 'scoring', '')
#        post :create_profile, post_params.merge(postback_url: 'http://some.random.other.url.com')
#      end
#    end
#
#    context 'POST /profile -- existing user' do
#      let!(:user) { FactoryGirl.create(:fb_user) }
#      let(:post_params_existing_user) { new_params = post_params; new_params[:token] = user.token; new_params }
#
#      before do
#        Resque.should_receive(:enqueue).with(FacebookFetcher, user.to_param, 'scoring', post_params[:postback_url])
#      end
#
#      it 'associates api_client' do
#        expect {
#          post :create_profile, post_params_existing_user
#        }.to change{api_client.reload.user_ids}.from([]).to([user.id])
#      end
#
#      it 'will not associate api_client more than once' do
#        user.api_clients << api_client
#        expect {
#          post :create_profile, post_params_existing_user
#        }.not_to change{user.reload.api_client_ids.length}
#      end
#
#      it 'finds existing fb profile' do
#        fb_profile = FactoryGirl.create(:facebook_profile, user: user)
#        post :create_profile, post_params_existing_user
#        assigns(:facebook_profile).should == fb_profile
#      end
#    end
#
#    context 'POST /profile -- invalid FB OAuth token' do
#      before do
#        FacebookProfile.should_receive(:find_or_create_by_token).
#            and_raise(Koala::Facebook::APIError.new("message"=>"Invalid OAuth access token.", "type"=>"OAuthException", "code"=>190))
#      end
#      it 'reports unprocessable entity (422) and error code' do
#        post :create_profile, post_params
#        response.status.should == 422
#        JSON.parse(response.body).should == {'errors' => 'OAuthException: Invalid OAuth access token.'}
#      end
#    end
#
#    context 'GET /score -- non-existent user' do
#      it 'returns 404' do
#        get :score, uid: '444444', api_key: api_client.api_key
#        response.status.should == 404
#      end
#    end
#
#    context 'GET /score -- existing user' do
#      let!(:wolf_facebook_profile) { FactoryGirl.create(:facebook_profile, trust_score: 66, profile_maturity: 78) }
#      let!(:user) { facebook_profile.user }
#
#      it 'is successful and contains uid, profile_maturity and trust_score in response' do
#        api_client.users << user
#        get :score, uid: user.uid, api_key: api_client.api_key
#        response.should be_success
#        JSON.parse(response.body).should == {uid: user.uid, trust_score: 66, profile_maturity: 78}.with_indifferent_access
#      end
#
#      it 'is denied if attempting to access user with other API credentials' do
#        get :score, uid: user.uid, api_key: api_client.api_key
#        response.status.should == 401
#      end
#    end
#
#  end
#
#  context 'unknown API key' do
#    it 'POST responds with 401 -- unauthorized' do
#      post :create_profile
#      response.status.should == 401
#    end
#
#    it 'GET responds with 401 -- unauthorized' do
#      get :score, uid: '123456', api_key: 'abcdefg'
#      response.status.should == 401
#    end
#  end
#
#end