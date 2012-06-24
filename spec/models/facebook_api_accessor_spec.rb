# encoding: utf-8

require 'spec_helper'

def verify_lars(user, ff, uid)
  user.name.should == 'Lars Kamp'
  user.uid.should == uid.to_s
  ff.mutual_friend_count.should == 5 # current FB data
  ff.can_post.should be_true
end

def verify_weidong(user, ff, uid)
  user.name.should == 'Weidong Yang'
  user.uid.should == uid.to_s
  ff.mutual_friend_count.should == 15 # current FB data
  ff.can_post.should be_true
end

describe FacebookProfile do

  context '#import_profile_and_network!'

  context 'FB Queries' do
    let!(:wolf_user) {FactoryGirl.create(:wolf_user)}
    let!(:wolf_fp)   {wolf_user.create_facebook_profile.reload}  # need reload here, otherwise we get some decorated Mongoid object, because Mongo doesn't return the object after a create operation unless 'safe' is on
    let!(:batch_client_mock) { mock('batch_client_mock') }

    before do
      class << wolf_fp
        public :add_to_fb_batch_query, :queue_all_friends
      end
    end

    context '#queue_all_friends' do

      it "sub-selects all UID's with connection to me" do
        wolf_fp.should_receive(:add_to_fb_batch_query).and_yield batch_client_mock
        batch_client_mock.should_receive(:fql_query).with(/FROM user WHERE uid IN \(SELECT uid2 FROM friend WHERE uid1=me\(\)\)/)

        wolf_fp.queue_all_friends
      end

      it "only queries the UID's provided" do
        wolf_fp.should_receive(:add_to_fb_batch_query).with(:friends).and_yield batch_client_mock
        batch_client_mock.should_receive(:fql_query).with(/FROM user WHERE uid IN \(123098,98543\)/)

        wolf_fp.queue_all_friends([123098, 98543])
      end
    end
  end

  context '#generate_friends_records!' do
    let!(:wolf_user)  { FactoryGirl.create(:wolf_user) }
    let!(:wolf_fp)    { wolf_user.create_facebook_profile }
    let(:lars_uid)    { 553647753 }
    let(:weidong_uid) { 563900754 }

    before :all do
      VCR.use_cassette('facebook/wolf_about_me_and_lars_and_weidong') do
        wolf_fp.friends.should be_nil
        wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid])
        wolf_fp.friends.should_not be_empty
      end
    end

    it 'generates a User and FacebookProfile record for every friend and sets up friendships' do
      expect {
      expect {
        wolf_fp.generate_friends_records!
      }.to change(User,:count).by(2)
      }.to change(FacebookProfile,:count).by(2)
    end

    it '#create_or_update_friendships(friend_fp, friend_raw) enters two friendship records for each friend' do
      expect {
        wolf_fp.generate_friends_records!
      }.to change{wolf_fp.facebook_friendships.count}.by(2)
      ffs = wolf_fp.facebook_friendships.all

      user1 = FacebookProfile.find(ffs[0].facebook_profile_to_id)
      user2 = FacebookProfile.find(ffs[1].facebook_profile_to_id)

      if user1.name == 'Lars Kamp'
        verify_lars(lars = user1, ff_lars = ffs[0], lars_uid)
        verify_weidong(weidong = user2, ff_weidong = ffs[1], weidong_uid)
      else
        verify_weidong(weidong = user1, ff_weidong = ffs[0], weidong_uid)
        verify_lars(lars = user2, ff_lars = ffs[1], lars_uid)
      end

      # reciprocal connections
      ff_lars = FacebookFriendship.where(facebook_profile_from_id: lars.id).first
      ff_lars.mutual_friend_count.should == 5
      ff_lars.can_post.should be_nil  # not set on reciprocal relationship (directional attribute)
      ff_weidong = FacebookFriendship.where(facebook_profile_from_id: weidong.id).first
      ff_weidong.mutual_friend_count.should == 15
      ff_weidong.can_post.should be_nil  # not set on reciprocal relationship (directional attribute)
    end

    it "writes data on friends from FB into info_via_friend" do
      wolf_fp.generate_friends_records!
      wei = FacebookProfile.where(uid: weidong_uid).first

      wei.name.should == 'Weidong Yang'
      wei.image.should == 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/370434_563900754_1952612728_s.jpg'
      wei.info.should be_nil
      wei.locations.should be_nil
      wei.info_via_friend.keys.should == ApiHelpers::FacebookApiAccessor::FB_FIELDS_FRIENDS
      # Note: Not all fields om info_via_friend are non-null
    end

  end
end
