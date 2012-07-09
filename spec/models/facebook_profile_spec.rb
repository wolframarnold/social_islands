require 'spec_helper'

describe FacebookProfile do

  context 'photo_engagements' do

    xit { should respond_to(:photo_engagements)}

    xit { should respond_to(:compute_photo_engagements)}

  end

  context '.find_or_create_by_token_and_api_key' do

    context 'FB Profile exists' do
      let!(:wolf_fp) { create(:wolf_facebook_profile) }

      it 'returns FB Profile' do
        FacebookProfile.find_or_create_by_token_and_api_key(
            token: wolf_fp.token, api_key: wolf_fp.api_key).should == wolf_fp
      end
    end

    context 'FB Profile for token and API key does not exist' do
      it 'looks up UID from FB and calls .find_or_create_by_uid_and_api_key' do
        FacebookProfile.should_receive(:get_uid_name_image).with('token_123qwer').
            and_return('uid' => 'uid_7654321', 'name' => 'John Smith', 'image' => 'http://example.com/john_smith.jpg')
        FacebookProfile.should_receive(:find_or_create_by_uid_and_api_key).with hash_including(api_key: 'api_key_zzzxxxcccvvv', uid: 'uid_7654321', token: 'token_123qwer')

        FacebookProfile.find_or_create_by_token_and_api_key(
            token: 'token_123qwer', api_key: 'api_key_zzzxxxcccvvv')
      end
    end

  end

  context '.find_or_create_by_uid_and_api_key' do

    context 'FB Profile exists' do
      let!(:wolf_fp) { create(:wolf_facebook_profile) }

      it 'returns FB Profile' do
        FacebookProfile.find_or_create_by_uid_and_api_key(
            uid: wolf_fp.uid, api_key: wolf_fp.api_key).should == wolf_fp
      end
    end
    context 'FB Profile for UID *and* API key does not exist' do
      before { Time.stub!(:now).and_return(Time.utc(2012)) }
      let!(:api_client) { create(:api_client, api_key: 'api_key_098zyx')}
      let(:params) { {uid: 'uid_123abc', api_key: 'api_key_098zyx',
                      token: 'token_567dfg', token_expires: true, token_expires_at: 3.months.from_now,
                      name: 'John Smith', image: 'http://example.com/john_smith.jpg',
                      postback_url: 'http://api.example.com/postback'} }

      it 'creates FB Profile and User, setting optional parameters' do
        expect {
          expect {
            fp = FacebookProfile.find_or_create_by_uid_and_api_key(params)
            fp.should be_kind_of(FacebookProfile)
            fp.user.should_not be_nil
            fp.user.name.should == 'John Smith'
            fp.user.image.should == 'http://example.com/john_smith.jpg'
          }.to change(FacebookProfile,:count).by(1)
        }.to change(User,:count).by(1)
      end
      it 'sets UID, API Key, Token and Token Expiry and other attributes on FacebookProfile' do
        fp = FacebookProfile.find_or_create_by_uid_and_api_key(params)
        fp.uid.should == 'uid_123abc'
        fp.api_key.should == 'api_key_098zyx'
        fp.token.should == 'token_567dfg'
        fp.token_expires.should be_true
        fp.postback_url.should == 'http://api.example.com/postback'
        # There seems to be some subtle issue with time comparison where the value
        # differs by a few milliseconds, even when stubbed -- may be a platform-specific issue
        fp.token_expires_at.utc.to_s.should == 3.months.from_now.to_datetime.to_s
      end
    end

    context 'FB Profile for UID but different API key exists' do
      let!(:wolf_fp) { create(:wolf_facebook_profile, uid: 'uid_123abc', api_key: 'api_key_5555aaaa') }
      let!(:user)       { wolf_fp.user }
      let(:params) { {uid: 'uid_123abc', api_key: 'api_key_098zyx', token: 'token_567dfg'} }

      it 'creates FB Profile' do
        expect {
          FacebookProfile.find_or_create_by_uid_and_api_key(params)
        }.to change(FacebookProfile, :count).by(1)
      end
      it 'links up to existing User, rather than creating a new one' do
        expect {
          fp = FacebookProfile.find_or_create_by_uid_and_api_key(params)
          fp.user.should == user
        }.to_not change(User, :count)
      end
    end

    context 'postback_url domain validation' do
      let!(:wolf_fp)    { create(:wolf_facebook_profile) }
      let!(:api_client) { ApiClient.where(api_key: wolf_fp.api_key).first }

      it 'rejects missing postback domain' do
        api_client.update_attribute(:postback_domain,nil)
        wolf_fp.postback_url = 'https://api.example.com/trustcc-postback'
        wolf_fp.should_not be_valid
        wolf_fp.errors[:postback_url].should == ["requires a 'postback_domain' on file. Cannot use postback mechanism without it. Configure it on API dashboard."]
      end
      it 'rejects non-matching postback domain' do
        wolf_fp.postback_url = 'https://joe_smith.example.com/trustcc-postback'
        wolf_fp.should_not be_valid
        wolf_fp.errors[:postback_url].should == ["does not match 'postback_domain' on file. Postback mechanism disallowed."]
      end
    end

  end

end