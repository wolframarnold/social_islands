require 'spec_helper'

describe ApiController do

  before do
    request.accept = Mime::JSON
  end

  # ENHANCEMENTS: store 3rd party customer ID

  context 'accepted credentials and known APP ID' do
    let!(:fp)         { create(:wolf_facebook_profile) }
    let!(:wolf_fp)    { fp }
    let!(:api_client) { ApiClient.where(app_id: fp.app_id).first }
    let(:post_params_valid) { { token: fp.token, app_id: api_client.app_id, app_key: 'secret_app_key', postback_url: "http://#{api_client.postback_domain}/trustcc" } }
    let(:post_params)  { post_params_valid }  # overridable to emulate different scenarios
    let(:postback_url) { post_params[:postback_url]}
    let(:fp_id)        { fp.uid }

    before do
      @success_response = ThreeScale::Response.new
      @success_response.success!
      ThreeScale.client.should_receive(:authorize).with('app_id'=>wolf_fp.app_id, 'app_key'=>'secret_app_key').and_return(@success_response)
      Resque.stub!(:enqueue)
    end

    context 'POST /trust_check' do
      render_views
      # DOC: if both token and UID given, token prevails
      # Same API -- pass in whatever is available. E.g. token may only be avaialble on mobile device
      # but FB ID or customer ID may also be available on central server -- can use to retrieve score
      # if provided FB ID takes precedence in lookup over customer ID

      ###########################################
      ###        Shared Example Groups        ###
      ###########################################

      shared_examples 'score not ready' do
        before do
          Resque.should_receive(:enqueue).with(FacebookFetcher,a_kind_of(String),'scoring',postback_url)
          post :trust_check, post_params
        end
        it 'sends 202 Accepted' do
          response.status.should == 202
        end
        it 'sends a message' do
          JSON.parse(response.body).should == {facebook_id: fp_id,
                                               message: "Scores are being computed. Poll this interface or listen for a postback.",
                                               postback_url: postback_url}.with_indifferent_access
          #postback_customer_id: 'hashed_customer_id_123'}
        end
      end
      shared_examples 'score ready' do
        let(:profile_authenticity) { 89.2 }
        let(:trust_score)          { 75.6 }
        before do
          fp.profile_authenticity = profile_authenticity
          fp.trust_score = trust_score
          fp.save
          post :trust_check, post_params
        end
        it 'sends 200 OK' do
          response.should be_ok
        end
        it 'sends scores and facebook_id' do
          JSON.parse(response.body).should == {facebook_id: fp.uid, profile_authenticity: profile_authenticity, trust_score: trust_score, name: 'Wolfram Arnold', image: 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/371822_595045215_1563438209_q.jpg'}.with_indifferent_access
        end
      end
      shared_examples 'record is created' do
        it 'created an FB profile and associated User record' do
          expect {
            expect {
              post :trust_check, post_params
              assigns(:facebook_profile).user.should_not be_nil
            }.to change(FacebookProfile,:count).by(1)
          }.to change(User,:count).by(1)
        end
      end
      shared_examples 'no record is created' do
        it 'created an FB profile and associated User record' do
          expect {
            expect {
              post :trust_check, post_params
            }.to_not change(FacebookProfile,:count)
          }.to_not change(User,:count)
        end
      end
      shared_examples 'not found' do
        it 'sends 404 Not Found' do
          post :trust_check, post_params
          response.should be_not_found
        end
      end
      shared_examples 'can update postback_url' do
        it 'sends 422 Unprocessable Entity if postback_url does not match domain' do
          ApiClient.any_instance.stub(:update_from_api_manager)
          post_params[:postback_url] = 'http://joesmith.example.com/trustcc'
          post :trust_check, post_params
          response.status.should == 422
          JSON.parse(response.body).should == {'errors' => {'postback_url' => ["does not match 'postback_domain' on file. Postback mechanism disallowed."]}}
        end
        it 'updates postback_url' do
          post_params[:postback_url].should_not be_blank
          post_params[:postback_url] += '/abc'
          post :trust_check, post_params
          assigns(:facebook_profile).should be_valid
          assigns(:facebook_profile).postback_url.should == post_params[:postback_url]
        end
      end

      ###########################################
      ###              Scenarios              ###
      ###########################################

      context 'params: app_id only -- invalid' do
        it 'sends 422 Unprocessable Entity' do
          post :trust_check, post_params.slice(:app_id,:app_key)
          response.status.should == 422
          JSON.parse(response.body).should == {'errors' => {'base' => ["'app_id' and 'token' or 'facebook_id' parameters are required!"]}}
        end
      end
      context 'params: facebook_token and app_id -- new record' do
        let(:post_params) { post_params_valid.merge(token: fp_wei.token) }
        let(:fp_wei)      { build(:wei_facebook_profile) }
        let(:fp_id)      { fp_wei.uid }
        before            { FacebookProfile.should_receive(:get_facebook_id_name_image).with(fp_wei.token).and_return('name'=>fp_wei.name, 'image'=>fp_wei.image, 'uid'=>fp_wei.uid) }
        it_behaves_like 'score not ready'
        it_behaves_like 'can update postback_url'
        it_behaves_like 'record is created'
      end
      context 'params: facebook_token and app_id -- matching existing record' do
        it_behaves_like 'score not ready'
        it_behaves_like 'score ready'
        it_behaves_like 'can update postback_url'
        it_behaves_like 'no record is created'
      end
      context 'params: facebook_token and app_id -- existing record, token changed, UID matches' do
        let(:post_params) { post_params_valid.merge(token: 'abcef_new_token') }
        before do
          FacebookProfile.should_receive(:get_facebook_id_name_image).with('abcef_new_token').and_return('name'=>fp.name, 'image'=>fp.image, 'uid'=>fp.uid)
          Resque.should_receive(:enqueue)  # we rec-ompute the score
        end
        it 'updates token' do
          post :trust_check, post_params
          assigns(:facebook_profile).token.should == 'abcef_new_token'
          assigns(:facebook_profile).should_not be_changed  # was saved
        end
        it 'sends score not ready if no scores for some reason' do
          post :trust_check, post_params
          response.status.should == 202
        end
        it 'sends score ready if available' do
          wolf_fp.trust_score = 90
          wolf_fp.profile_authenticity = 89
          wolf_fp.save

          post :trust_check, post_params
          response.status.should == 200
          JSON.parse(response.body).should include('trust_score' => 90.0, 'profile_authenticity' => 89.0)
        end
      end
      context 'params: facebook_id and app_id no token -- matching record' do
        let(:post_params) { post_params_valid.except(:token).merge(facebook_id: fp.uid) }
        it_behaves_like 'score not ready'
        it_behaves_like 'score ready'
        it_behaves_like 'can update postback_url'
      end
      context 'params: facebook_id and app_id, no token -- non-matching record' do
        let(:post_params) { {app_id: fp.app_id, app_key: 'secret_app_key', facebook_id: fp_id+1} }
        it_behaves_like 'not found'
      end

    end

    context 'unknown app_id' do
      before do
        api_client.destroy
      end
      it 'creates an ApiClient record' do
        VCR.use_cassette('3scale/rubyfocus_developer_app') do
          expect {
            post :trust_check, post_params.except(:token)
          }.to change(ApiClient, :count).by(1)
        end
      end
    end

  end

  context 'failing credentials' do

    context 'app_id and/or app_key missing' do
      it 'missing: sends with 401 Unauthorized' do
        post :trust_check
        response.response_code.should == 401
        response.headers.should include('WWW-Authenticate'=>'api_key api_id tuple realm="api.trust.cc"')
        JSON.parse(response.body).should == {'errors'=>{'app_key'=>['must be provided'],'app_id'=>['must be provided']}}
      end
    end

    context 'app_id, app_key present but 3Scale authorization failed' do
      before do
        error_response = ThreeScale::Response.new
        error_response.error!('Something went wrong!', 999)
        ThreeScale.client.should_receive(:authorize).with('app_id'=>'my_app_id', 'app_key'=>'my_app_key').and_return(error_response)
      end

      it 'missing: sends with 401 Unauthorized' do
        post :trust_check, app_id: 'my_app_id', app_key: 'my_app_key'
        response.response_code.should == 401
        response.headers.should include('WWW-Authenticate'=>'api_key api_id tuple realm="api.trust.cc"')
        JSON.parse(response.body).should == {'errors'=>{'base'=>['Authorization failed! Code: 999 "Something went wrong!"']}}
      end
    end

  end

end