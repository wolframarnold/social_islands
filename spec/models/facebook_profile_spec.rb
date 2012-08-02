require 'spec_helper'

describe FacebookProfile do

  context '.update_or_create_by_token_or_facebook_id_and_app_id' do

    shared_examples 'FB Profile for token and APP ID does not exist' do
      it 'looks up UID from FB and calls .find_or_create_by_uid_and_app_id' do
        FacebookProfile.should_receive(:get_facebook_id_name_image).with(params[:token]).
            and_return('uid' => uid, 'name' => 'John Smith', 'image' => 'http://example.com/john_smith.jpg')
        FacebookProfile.should_receive(:update_or_create_by_facebook_id_and_app_id).with hash_including(params.merge(uid: uid))

        FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(params)
      end
    end

    context 'token and app_id' do

      context 'FB Profile exists' do
        let!(:wolf_fp) { create(:wolf_facebook_profile) }

        it 'returns FB Profile' do
          FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(
              token: wolf_fp.token, app_id: wolf_fp.app_id).should == wolf_fp
        end

        it 'updates FB Profile' do
          expect {
            FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(
                token: wolf_fp.token, app_id: wolf_fp.app_id, postback_url: 'http://api.example.com/postback')
            wolf_fp.reload
          }.to change{wolf_fp.postback_url}.from(nil).to('http://api.example.com/postback')
        end

        it 'returns an error if update fails' do
          api_client_mock = mock('ApiClient',postback_domain: 'http://api.example.com', update_from_api_manager: nil)
          ApiClient.stub_chain :where, first: api_client_mock

          fp = FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(
              token: wolf_fp.token, app_id: wolf_fp.app_id, postback_url: 'http://joe_smith.example.com')
          fp.should_not be_valid
          fp.errors[:postback_url].should_not be_blank
        end

        it 'does not store parameters other than mass-assignable ones' do
          fp = FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(
              token: wolf_fp.token, app_id: wolf_fp.app_id, junk_param: 'store me')
          fp['junk_param'].should be_nil
        end

        it 'sets last_fetched_at to nil when token is not found but record exists' do
          FacebookProfile.should_receive(:get_facebook_id_name_image).with('my_new_token').
              and_return('uid' => wolf_fp.uid, 'name' => 'John Smith', 'image' => 'http://example.com/john_smith.jpg')
          wolf_fp.update_attribute(:last_fetched_at, Time.now)
          wolf_fp.should_fetch?.should be_false

          fp = FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(
              token: 'my_new_token', app_id: wolf_fp.app_id)

          fp.should == wolf_fp
          wolf_fp.reload.last_fetched_at.should be_nil
          wolf_fp.should_fetch?.should be_true
        end
      end

      it_behaves_like 'FB Profile for token and APP ID does not exist' do
        let(:params) { {token: 'token_123qwer', app_id: 'app_id_zzzxxxcccvvv'} }
        let(:uid)    { 'uid_7654321' }
      end

    end

    context 'token and uid and app_id' do
      it_behaves_like 'FB Profile for token and APP ID does not exist' do
        let(:params) { {token: 'token_123qwer', app_id: 'app_id_zzzxxxcccvvv', uid: 'uid_7654321'} }
        let(:uid)    { 'uid_7654321' }
      end
    end

    context 'facebook_id and app_id only' do
      it 'delegates to .update_or_create_by_facebook_id_and_app_id' do
        FacebookProfile.should_receive(:update_or_create_by_facebook_id_and_app_id)
        FacebookProfile.update_or_create_by_token_or_facebook_id_and_app_id(app_id: 'app_id_zzzxxxcccvvv', facebook_id: 'uid_7654321')
      end
    end
  end

  context '.update_or_create_by_facebook_id_and_app_id' do

    context 'FB Profile exists' do
      let!(:wolf_fp) { create(:wolf_facebook_profile) }

      it 'returns FB Profile' do
        FacebookProfile.update_or_create_by_facebook_id_and_app_id(
            facebook_id: wolf_fp.uid, app_id: wolf_fp.app_id).should == wolf_fp
      end
      it 'updates FB Profile' do
        expect {
          FacebookProfile.update_or_create_by_facebook_id_and_app_id(
              facebook_id: wolf_fp.uid, app_id: wolf_fp.app_id, postback_url: 'http://api.example.com/postback')
          wolf_fp.reload
        }.to change{wolf_fp.postback_url}.from(nil).to('http://api.example.com/postback')
      end
      it 'returns an error if update fails' do
        api_client_mock = mock('ApiClient',postback_domain: 'http://api.example.com', update_from_api_manager: nil)
        ApiClient.stub_chain :where, first: api_client_mock

        fp = FacebookProfile.update_or_create_by_facebook_id_and_app_id(
            facebook_id: wolf_fp.uid, app_id: wolf_fp.app_id, postback_url: 'http://joe_smith.example.com')
        fp.should_not be_valid
        fp.errors[:postback_url].should_not be_blank
      end
    end

    context 'FB Profile for UID *and* APP ID does not exist' do
      before { Time.stub!(:now).and_return(Time.utc(2012)) }
      let!(:api_client) { create(:api_client, app_id: 'app_id_098zyx')}
      let(:params) { {facebook_id: 'uid_123abc', app_id: 'app_id_098zyx',
                      token: 'token_567dfg', token_expires: true, token_expires_at: 3.months.from_now,
                      name: 'John Smith', image: 'http://example.com/john_smith.jpg',
                      postback_url: 'http://api.example.com/postback'} }

      it 'creates FB Profile and User, setting optional parameters' do
        expect {
          expect {
            fp = FacebookProfile.update_or_create_by_facebook_id_and_app_id(params)
            fp.should be_kind_of(FacebookProfile)
            fp.user.should_not be_nil
            fp.user.name.should == 'John Smith'
            fp.user.image.should == 'http://example.com/john_smith.jpg'
          }.to change(FacebookProfile,:count).by(1)
        }.to change(User,:count).by(1)
      end
      it 'sets UID, APP ID, Token and Token Expiry and other attributes on FacebookProfile' do
        fp = FacebookProfile.update_or_create_by_facebook_id_and_app_id(params)
        fp.uid.should == 'uid_123abc'
        fp.app_id.should == 'app_id_098zyx'
        fp.token.should == 'token_567dfg'
        fp.token_expires.should be_true
        fp.postback_url.should == 'http://api.example.com/postback'
        # There seems to be some subtle issue with time comparison where the value
        # differs by a few milliseconds, even when stubbed -- may be a platform-specific issue
        fp.token_expires_at.utc.to_s.should == 3.months.from_now.to_datetime.to_s
      end
    end

    context 'FB Profile for UID but different APP ID exists' do
      let!(:wolf_fp) { create(:wolf_facebook_profile, uid: 'uid_123abc', app_id: 'app_id_5555aaaa') }
      let!(:user)       { wolf_fp.user }
      let(:params) { {facebook_id: 'uid_123abc', app_id: 'app_id_098zyx', token: 'token_567dfg'} }

      it 'creates FB Profile' do
        expect {
          FacebookProfile.update_or_create_by_facebook_id_and_app_id(params)
        }.to change(FacebookProfile, :count).by(1)
      end
      it 'links up to existing User, rather than creating a new one' do
        expect {
          fp = FacebookProfile.update_or_create_by_facebook_id_and_app_id(params)
          fp.user.should == user
        }.to_not change(User, :count)
      end
    end

    context '#postback_url_matched_domain' do
      let!(:wolf_fp)    { create(:wolf_facebook_profile) }
      let!(:api_client) { ApiClient.where(app_id: wolf_fp.app_id).first }

      before do
        ApiClient.any_instance.should_receive(:update_from_api_manager)
      end

      context 'missing postback domain' do
        before do
          wolf_fp.postback_url = 'https://api.example.com/trustcc-postback'
          api_client.update_attribute(:postback_domain,nil)
        end

        it 'rejects missing postback domain' do
          wolf_fp.should_not be_valid
          wolf_fp.errors[:postback_url].should == ["requires a 'postback_domain' on file. Cannot use postback mechanism without it. Configure it on API dashboard."]
        end
      end

      context 'non-matching postback domain' do
        before do
          wolf_fp.postback_url = 'https://joe_smith.example.com/trustcc-postback'
        end

        it 'rejects non-matching postback domain' do
          wolf_fp.should_not be_valid
          wolf_fp.errors[:postback_url].should == ["does not match 'postback_domain' on file. Postback mechanism disallowed."]
        end
      end
    end

  end

end