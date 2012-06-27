# encoding: utf-8

require 'spec_helper'

describe FacebookProfile do

  let!(:wolf_fp)    { create :facebook_profile }
  let(:lars_uid)    { 553647753 }
  let(:weidong_uid) { 563900754 }

  before :all do
    VCR.use_cassette('facebook/wolf_about_me_and_lars_and_weidong') do
      wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid])
    end
  end

  context '#import_profile_and_network!' do

    before do
      wolf_fp.should_receive(:execute_fb_batch_query).twice
      wolf_fp.about_me = {'id' => wolf_fp.to_param, 'name' => wolf_fp.name}
    end

    it 'batches all requests' do
      wolf_fp.import_profile_and_network!
      batched_attrs = wolf_fp.instance_variable_get(:@batched_attributes)
      batched_attrs.should include(attr: :edges, chunked: true)
      batched_attrs.should include(attr: :photos, chunked: false)
      batched_attrs.should include(attr: :image, chunked: false)
      batched_attrs.should include(attr: :posts, chunked: false)
      batched_attrs.should include(attr: :tagged, chunked: false)
      batched_attrs.should include(attr: :locations, chunked: false)
      batched_attrs.should include(attr: :statuses, chunked: false)
      batched_attrs.should include(attr: :about_me, chunked: false)
    end

    it 'sets last_fetched_at' do
      wolf_fp.import_profile_and_network!
      wolf_fp.last_fetched_at.should_not be_nil
    end
  end

  context 'FB Queries' do
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
    it 'generates a User and FacebookProfile record for every friend' do
      expect {
      expect {
        wolf_fp.generate_friends_records!
      }.to change(User,:count).by(2)
      }.to change(FacebookProfile,:count).by(2)
    end

    it "writes about me data on friends from FB into fields_via_friend" do
      wolf_fp.generate_friends_records!
      wei = FacebookProfile.where(uid: weidong_uid).first

      wei.about_me.should be_nil
      wei.locations.should be_nil
      wei.fields_via_friend.keys.should == ApiHelpers::FacebookApiAccessor::FB_FIELDS_FRIENDS
      # Note: Not all fields om fields_via_friend are non-null
    end

    it "for a friend record denormalizes name, image, token, api_key" do
      wolf_fp.generate_friends_records!
      wei = FacebookProfile.where(uid: weidong_uid).first

      wei.name.should == 'Weidong Yang'
      wei.image.should == 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/370434_563900754_1952612728_s.jpg'
      wei.token.should == wolf_fp.token
      wei.api_key.should == wolf_fp.api_key
    end

    context '#create_or_update_friendships' do

      it 'creates two friendship records for each friend, by UID' do
        expect {
          expect {
            wolf_fp.generate_friends_records!
          }.to change{FacebookFriendship.from(wolf_fp).count}.by(2)
        }.to change{FacebookFriendship.count}.by(4)
      end

      it 'can retrieve friends using scope: friends_with_variations' do
        wolf_fp.generate_friends_records!
        lars, weidong = wolf_fp.friends_variants.order([:name, :asc]).all

        lars.name.should == 'Lars Kamp'
        lars.uid.should == lars_uid

        weidong.name.should == 'Weidong Yang'
        weidong.uid.should == weidong_uid
      end

      it 'can retrieve friendship; records "can_post" uni-directionally and "mutual_friend_count" bi-directionally' do
        wolf_fp.generate_friends_records!
        friendships = wolf_fp.friendships
        friendships.count.should == 2
        friendships.map(&:facebook_profile_to_uid).should =~ [lars_uid, weidong_uid]
        friendships.map(&:can_post).should == [true, true]
        friendships.map(&:mutual_friend_count).should =~ [5, 15]

        lars, weidong = wolf_fp.friends_variants.order([:name, :asc]).to_a

        lars.friendships.count.should == 1
        lars.friendships[0].mutual_friend_count.should == 5 # current FB data
        lars.friendships[0].can_post.should be_nil
        weidong.friendships.count.should == 1
        weidong.friendships[0].mutual_friend_count.should == 15 # current FB data
        weidong.friendships[0].can_post.should be_nil
      end

      it 'does not write duplicate friendships if they exist already' do
        # This can happen since we allow multiple FB Profile records with the same
      end
    end

  end
end
