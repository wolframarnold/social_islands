# encoding: utf-8

require 'spec_helper'

describe FacebookProfile do

  #let!(:user) {FactoryGirl.create(:fb_user)}

  #context 'detects attributes without loading them' do
  #  before do
  #    @fb = FactoryGirl.create(:facebook_profile, user: user)
  #    Mongoid::IdentityMap.clear  # prevent cache from holding graph
  #    @fb = FacebookProfile.find(@fb.to_param)
  #    @fb.graph.should be_nil
  #  end
  #
  #  it 'graph' do
  #    expect {
  #      @fb.should have_graph
  #    }.to_not change(@fb, :graph)
  #  end
  #
  #  # Mongoid removed more than one $ne clause -- not sure this is a Mongoid bug or a native MongoDB limitation
  #  # couldn't figure out how to test for both conditions easily $nin => [nil, ''] didn't seem to work either.
  #  #it 'detects "" as not present' do
  #  #  @fb.set(:graph, '')
  #  #  Mongoid::IdentityMap.clear  # prevent cache from holding graph
  #  #  @fb.should_not have_graph
  #  #end
  #
  #  it 'detects nil as not present' do
  #    @fb.unset(:graph)
  #    Mongoid::IdentityMap.clear  # prevent cache from holding graph
  #    @fb.should_not have_graph
  #  end
  #
  #  it 'edges' do
  #    expect {
  #      @fb.should have_graph
  #    }.to_not change(@fb, :edges)
  #  end
  #end

  context 'photo_engagements' do

    xit { should respond_to(:photo_engagements)}

    xit { should respond_to(:compute_photo_engagements)}

  end

  #context 'API use: .find_or_create_by_token' do
  #
  #  context 'FBProfile and User records exist' do
  #    let!(:fb_profile) { FactoryGirl.create(:facebook_profile, user: user) }
  #
  #    context 'token matches' do
  #
  #      it 'returns record' do
  #        FacebookProfile.find_or_create_by_token(fb_profile.token).should == fb_profile
  #      end
  #      it 'does not create a new record' do
  #        expect {
  #          FacebookProfile.find_or_create_by_token(fb_profile.token)
  #        }.should_not change(FacebookProfile,:count)
  #      end
  #    end
  #    context 'token does not match' do
  #      before do
  #        Koala::Facebook::API.any_instance.should_receive(:get_object).
  #            with('me', fields: 'id').
  #            and_return('id'=>fb_profile.uid)
  #      end
  #      it 'finds record by UID' do
  #        FacebookProfile.find_or_create_by_token(fb_profile.token+'123').should == fb_profile
  #      end
  #      it 'does not create a new record' do
  #        expect {
  #          FacebookProfile.find_or_create_by_token(fb_profile.token+'123')
  #        }.should_not change(FacebookProfile,:count)
  #      end
  #      it 'updates token' do
  #        old_token = fb_profile.token
  #        expect {
  #          FacebookProfile.find_or_create_by_token(fb_profile.token+'123')
  #        }.should change{fb_profile.user.reload.token}.from(old_token).to(old_token+'123')
  #      end
  #    end
  #  end
  #
  #  context 'User record exists but FBProfile does not' do
  #    it 'creates a new FBProfile record' do
  #      expect {
  #        fp = FacebookProfile.find_or_create_by_token(user.token)
  #        fp.user.should == user
  #      }.to change(FacebookProfile,:count).by(1)
  #    end
  #    it 'does not create a new User record' do
  #      expect {
  #        FacebookProfile.find_or_create_by_token(user.token)
  #      }.to_not change(User,:count)
  #    end
  #  end
  #
  #  context 'neither FBProfile nor User record does not exist' do
  #    before do
  #      Koala::Facebook::API.any_instance.should_receive(:get_object).
  #          with('me', fields: 'id').
  #          and_return('id'=>'7654321')
  #    end
  #    it 'creates a new record' do
  #      expect {
  #        FacebookProfile.find_or_create_by_token('zxcvlkjh768')
  #      }.to change(FacebookProfile,:count).by(1)
  #    end
  #    it 'creates a new user' do
  #      expect {
  #        fp = FacebookProfile.find_or_create_by_token('zxcvlkjh768')
  #        fp.user.should_not be_nil
  #        fp.user.uid.should == '7654321'
  #      }.to change(User,:count).by(1)
  #    end
  #  end
  #
  #end

  context '.find_or_create_by_token_and_api_key' do

    context 'FB Profile exists' do
      let!(:fb_profile) { create(:facebook_profile) }

      it 'returns FB Profile' do
        FacebookProfile.find_or_create_by_token_and_api_key(
            token: fb_profile.token, api_key: fb_profile.api_key).should == fb_profile
      end
    end

    context 'FB Profile for token and API key does not exist' do
      it 'looks up UID from FB and calls .find_or_create_by_uid_and_api_key' do
        FacebookProfile.should_receive(:get_uid).with('token_123qwer').and_return('uid_7654321')
        FacebookProfile.should_receive(:find_or_create_by_uid_and_api_key).with hash_including(api_key: 'api_key_zzzxxxcccvvv', uid: 'uid_7654321', token: 'token_123qwer')

        FacebookProfile.find_or_create_by_token_and_api_key(
            token: 'token_123qwer', api_key: 'api_key_zzzxxxcccvvv')
      end
    end

  end

  context '.find_or_create_by_uid_and_api_key' do

    context 'FB Profile exists' do
      let!(:fb_profile) { create(:facebook_profile) }

      it 'returns FB Profile' do
        FacebookProfile.find_or_create_by_uid_and_api_key(
            uid: fb_profile.uid, api_key: fb_profile.api_key).should == fb_profile
      end
    end
    context 'FB Profile for UID *and* API key does not exist' do
      let(:params) { {uid: 'uid_123abc', api_key: 'api_key_098zyx', token: 'token_567dfg'} }
      it 'creates FB Profile and User' do
        expect {
          expect {
            fp = FacebookProfile.find_or_create_by_uid_and_api_key(params)
            fp.should be_kind_of(FacebookProfile)
            fp.user.should_not be_nil
          }.to change(FacebookProfile,:count).by(1)
        }.to change(User,:count).by(1)
      end
      it 'sets UID, API Key and Token on FacebookProfile' do
        fp = FacebookProfile.find_or_create_by_uid_and_api_key(params)
        fp.uid.should == 'uid_123abc'
        fp.api_key.should == 'api_key_098zyx'
        fp.token.should == 'token_567dfg'
      end
    end
    context 'FB Profile for UID but different API key exists' do
      let!(:fb_profile) { create(:facebook_profile, uid: 'uid_123abc', api_key: 'api_key_5555aaaa') }
      let!(:user)       { fb_profile.user }
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