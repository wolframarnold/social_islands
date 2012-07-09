require 'spec_helper'

describe ApiController do

  before do
    request.accept = Mime::JSON
  end

  # ENHANCEMENTS: store 3rd party customer ID

  context 'known API Key' do
    let!(:wolf_fp)    { create(:wolf_facebook_profile) }
    let!(:api_client) { ApiClient.where(api_key: wolf_fp.api_key).first }
    let(:post_params) { { token: 'abcdefghij', api_key: api_client.api_key } }

    context 'POST /profile' do
      before do
        Resque.should_receive(:enqueue).with(FacebookFetcher, instance_of(String), 'scoring')
        FacebookProfile.should_receive(:find_or_create_by_token_and_api_key).and_return(wolf_fp)
      end

      it 'sends 201 Created' do
        post :create_or_update_profile, post_params
        response.status.should == 201
      end
    end

    context 'POST /profile -- invalid params' do
      it 'returns 422 with error message if token or api_client are missing' do
        post :create_or_update_profile, post_params.except(:token)
        response.status.should == 422
        JSON.parse(response.body).should == {'errors' => ["'token' and 'api_key' parameters are required!"]}
      end
    end

    context "GET /score" do
      render_views

      let!(:wolf_fp) { create(:wolf_facebook_profile) }

      context 'if score is ready' do
        before do
          wolf_fp.update_attribute(:profile_authenticity, 89.2)
          wolf_fp.update_attribute(:trust_score, 78.4)
          get :score, facebook_profile_id: wolf_fp.uid, api_key: wolf_fp.api_key
        end
        it 'sends 200 OK' do
          response.response_code.should == 200
        end
        it 'replies with score' do
          JSON.parse(response.body).should == {facebook_profile_id: wolf_fp.uid,
                                               profile_authenticity: 89.2, trust_score: 78.4}.with_indifferent_access
        end
      end
      context 'if score is not ready' do
        let(:postback_params) { {postback_url: 'http://api.example.com/'} }
        before do
          Resque.should_receive(:enqueue).with(FacebookFetcher, wolf_fp.to_param, 'scoring', postback_params[:postback_url])
          get :score, {facebook_profile_id: wolf_fp.uid, api_key: wolf_fp.api_key}.merge(postback_params)
        end
        it 'sends 202 Accepted' do
          response.response_code.should == 202
        end
        it 'sends a message stating that the score is not ready' do
          JSON.parse(response.body).should == {facebook_profile_id: wolf_fp.uid,
                                               message: "Scores are being computed. Poll this interface or listen for a postback.",
                                               postback_url: 'http://api.example.com/'}.with_indifferent_access
                                               #postback_customer_id: 'hashed_customer_id_123'}
        end
      end
      context 'if score is not ready and postback_url is supplied but invalid' do
        it 'sends 422 Unprocessable Entity' do
          Resque.should_not_receive(:enqueue)
          get :score, facebook_profile_id: wolf_fp.uid, api_key: wolf_fp.api_key, postback_url: 'https://joesmith.example.com/'
          response.response_code.should == 422
          JSON.parse(response.body).should == {'errors' => {'postback_url' => ["does not match 'postback_domain' on file. Postback mechanism disallowed."]}}
        end
      end
      context 'if profile UID or Customer ID is unknown' do
        it 'sends 404 Not Found' do
          get :score, facebook_profile_id: '1236790', api_key: wolf_fp.api_key
          response.should be_not_found
        end
      end

      context 'if attempting to access user with other API credentials' do
        let!(:wei_fp)  { create(:wei_facebook_profile) }
        it 'is denied' do
          get :score, facebook_profile_id: wei_fp.uid, api_key: api_client.api_key
          response.should be_forbidden
        end
      end

    end

  end

  context 'unknown API key' do
    it 'POST responds with 403 -- forbidden' do
      post :create_or_update_profile
      response.should be_forbidden
    end

    it 'GET responds with 403 -- forbidden' do
      get :score, facebook_user_id: '123456', api_key: 'abcdefg'
      response.should be_forbidden
    end
  end

end