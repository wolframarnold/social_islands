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
      let(:params) { {uid: 'uid_123abc', api_key: 'api_key_098zyx',
                      token: 'token_567dfg', token_expires: true, token_expires_at: 3.months.from_now,
                      name: 'John Smith', image: 'http://example.com/john_smith.jpg'} }

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
      it 'sets UID, API Key, Token and Token Expiry on FacebookProfile' do
        fp = FacebookProfile.find_or_create_by_uid_and_api_key(params)
        fp.uid.should == 'uid_123abc'
        fp.api_key.should == 'api_key_098zyx'
        fp.token.should == 'token_567dfg'
        fp.token_expires.should be_true
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

  end

end