# encoding: utf-8

require 'spec_helper'

describe FacebookProfile do

  let!(:wolf_fp)    { create :wolf_facebook_profile }
  let(:lars_uid)    { 553647753 }
  let(:weidong_uid) { 563900754 }

  before do
    class << wolf_fp; public :get_engagement_data_and_network_graph; end
    VCR.use_cassette('facebook/wolf_about_me_and_lars_and_weidong', allow_playback_repeats: true) do
      wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid])
      wolf_fp.get_engagement_data_and_network_graph
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
      batched_attrs.should include(attr: :mutual_friends_raw, chunked: true)
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
        wolf_fp.should_receive(:add_to_fb_batch_query).with(:friends_raw).and_yield batch_client_mock
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

    it "includes friends array (as facebook_profile_uids) in direct user's record" do
      wolf_fp.generate_friends_records!
      wolf_fp.facebook_profile_uids.should =~ [lars_uid, weidong_uid]
    end

    it "friends arrays are many-to-many relationships with indirect users' (friends') records" do
      wolf_fp.generate_friends_records!
      friends = wolf_fp.facebook_profiles.order_by([:uid, :asc]).all # Lars has lower uid
      # Wolf & Lars mutual friends
      scott_thorpe_uid = 503484735
      moritz_von_der_linden_uid = 642633629
      meghan_hughes_uid = 697626226
      jutta_kamp_uid = 1466344023
      friends[0].facebook_profile_uids.should =~ [wolf_fp.uid, weidong_uid, scott_thorpe_uid, moritz_von_der_linden_uid, meghan_hughes_uid, jutta_kamp_uid]
      # Wolf & Weidong mutual friends
      weidong_wolf_mutual_friend_uids = [223888, 1200385, 532933782, 538362618, 567455648, 633819791, 641972802, 656512960, 746870400, 781849541, 1050211056, 1519692151, 100000549325522]
      friends[1].facebook_profile_uids.should =~ [wolf_fp.uid, lars_uid] + weidong_wolf_mutual_friend_uids
    end

    it "for a friend record denormalizes name, image, token, api_key" do
      wolf_fp.generate_friends_records!
      wei = FacebookProfile.where(uid: weidong_uid).first

      wei.name.should == 'Weidong Yang'
      wei.image.should == 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/370434_563900754_1952612728_s.jpg'
      wei.token.should == wolf_fp.token
      wei.api_key.should == wolf_fp.api_key
    end

    it 'sets can_post on self' do
      wolf_fp.generate_friends_records!
      wolf_fp.can_post.should =~ [lars_uid, weidong_uid]
    end

    context '#gather_friends_by_uid_from_raw_data' do
      before do
        class << wolf_fp; public :gather_friends_by_uid_from_raw_data; end
      end
      let(:mutual_friends_raw) { [{'uid1'=>'123','uid2'=>'456'}, {'uid1'=>'123','uid2'=>'457'}, {'uid1'=>'456','uid2'=>'123'}, {'uid1'=>'456','uid2'=>'457'}, {'uid1'=>'457','uid2'=>'456'}, {'uid1'=>'457','uid2'=>'123'}] }
      it 'groups by uid and turns into numbers' do
        wolf_fp.mutual_friends_raw = mutual_friends_raw
        wolf_fp.gather_friends_by_uid_from_raw_data.should == {123=>Set.new([456,457]), 456=>Set.new([123,457]), 457=>Set.new([123,456])}
      end
      it 'fills data gaps to make relationships symmetrical' do
        wolf_fp.mutual_friends_raw = mutual_friends_raw.values_at(0,3,5)
        wolf_fp.gather_friends_by_uid_from_raw_data.should == {123=>Set.new([456,457]), 456=>Set.new([123,457]), 457=>Set.new([123,456])}
      end
    end

  end
end
