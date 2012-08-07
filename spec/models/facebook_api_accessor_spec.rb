# encoding: utf-8

require 'spec_helper'

describe FacebookProfile do

  let!(:wolf_fp)  { create :wolf_facebook_profile, uid: 123, name: 'Joe', image: 'dummy' }

  before :all do
    class << wolf_fp; public :get_about_me_and_friends, :get_friends_details, :get_engagement_data_and_network_graph, :execute_as_batch_query; end
    VCR.insert_cassette 'facebook/wolf_about_me_and_lars_and_weidong'
  end

  after :all do
    VCR.eject_cassette
  end

  context 'FB Queries' do

    context '#get_about_me_and_friends' do
      before :all do
        wolf_fp.execute_as_batch_query { wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid]) }
      end

      it 'should store name, uid and image' do
        wolf_fp.name.should == 'Wolfram Arnold'
        wolf_fp.uid.should == wolf_uid
        wolf_fp.image.should == 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/371822_595045215_1563438209_q.jpg'
      end

      it 'should get friends raw data' do
        wolf_fp.friends_raw.should be_kind_of(Array)
        wolf_fp.friends_raw.should == [{'uid' => lars_uid,    'mutual_friend_count' => 5 , 'name' => 'Lars Kamp', 'pic' => 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash2/27430_553647753_3455_s.jpg'},
                                       {'uid' => weidong_uid, 'mutual_friend_count' => 15, 'name' => 'Weidong Yang', 'pic' => 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/370434_563900754_1952612728_s.jpg'}]
      end
    end

    #context '#get_friends_details' do
    #  before :all do
    #    wolf_fp.execute_as_batch_query { wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid]) }
    #    wolf_fp.execute_as_batch_query { wolf_fp.get_friends_details }
    #  end
    #
    #  it 'adds about me data, photos, posts, tagged, locations, statuses, likes, feed to friend hash' do
    #    wolf_fp.friends_raw.should have(2).entries
    #
    #    wolf_fp.friends_raw.each do |friend_raw|
    #      friend_raw.keys.should =~ %w(uid mutual_friend_count about_me photos posts tagged locations statuses likes feed)
    #      friend_raw['about_me'].should be_kind_of(Hash)
    #      friend_raw.except('uid','mutual_friend_count','about_me').each_value do |val|
    #        val.should be_kind_of(Array)
    #      end
    #    end
    #  end
    #end

    context '#get_engagement_data_and_network_graph' do
      before :all do
        wolf_fp.execute_as_batch_query { wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid]) }
        wolf_fp.execute_as_batch_query {
          #wolf_fp.get_friends_details  # see notes at definition
          wolf_fp.get_engagement_data_and_network_graph
        }
      end

      it 'adds permissions photos posts tagged locations statuses likes checkins feed to self' do
        %w(permissions photos posts tagged locations statuses likes checkins feed).each do |attr|
          wolf_fp.send(attr).should be_kind_of(Array)
          wolf_fp.send(attr).should_not be_empty unless attr == 'tagged'
        end
      end

      it 'sets mutual_friends_raw' do
        wolf_fp.mutual_friends_raw.should be_kind_of(Array)
        wolf_fp.mutual_friends_raw.should == [{"uid1"=>"553647753", "uid2"=>"503484735"}, {"uid1"=>"553647753", "uid2"=>"1466344023"}, {"uid1"=>"553647753", "uid2"=>"697626226"}, {"uid1"=>"553647753", "uid2"=>"563900754"}, {"uid1"=>"553647753", "uid2"=>"642633629"}, {"uid1"=>"563900754", "uid2"=>"746870400"}, {"uid1"=>"563900754", "uid2"=>"656512960"}, {"uid1"=>"563900754", "uid2"=>"781849541"}, {"uid1"=>"563900754", "uid2"=>"100000549325522"}, {"uid1"=>"563900754", "uid2"=>"641972802"}, {"uid1"=>"563900754", "uid2"=>"1519692151"}, {"uid1"=>"563900754", "uid2"=>"1050211056"}, {"uid1"=>"563900754", "uid2"=>"553647753"}, {"uid1"=>"563900754", "uid2"=>"1200385"}, {"uid1"=>"563900754", "uid2"=>"223888"}, {"uid1"=>"563900754", "uid2"=>"532933782"}, {"uid1"=>"563900754", "uid2"=>"538362618"}, {"uid1"=>"563900754", "uid2"=>"567455648"}, {"uid1"=>"563900754", "uid2"=>"633819791"}]
      end
    end

    context '#chunk_friends_by_mutual_friend_count' do
      before do
        wolf_fp.friends_raw = [{'uid' => 123, 'mutual_friend_count' => 1000},
                               {'uid' => 124, 'mutual_friend_count' => 3999},
                               {'uid' => 125, 'mutual_friend_count' =>  nil}, # will assume 5
                               {'uid' => 126, 'mutual_friend_count' =>   10}]
        class << wolf_fp; public :chunk_friends_by_mutual_friend_count; end
      end
      it 'returns friends chunked in groups of 5000' do
        wolf_fp.chunk_friends_by_mutual_friend_count.should == ['123,124', '125,126']
      end

    end
  end

  context '#create_friends_records_and_save_stats!' do
    before :all do
      wolf_fp.execute_as_batch_query { wolf_fp.get_about_me_and_friends([lars_uid, weidong_uid]) }
      wolf_fp.execute_as_batch_query {
        #wolf_fp.get_friends_details  # see notes at definition
        wolf_fp.get_engagement_data_and_network_graph
      }
    end

    before do
      Time.stub(:now).and_return(@now = Time.utc(2012))
    end

    it 'sets last_fetched_at, last_fetched_by and fetched_directly flags' do
      wolf_fp.update_attribute(:fetched_directly, false)
      wolf_fp.create_friends_records_and_save_stats!

      wolf_fp.last_fetched_at.should == @now
      wolf_fp.last_fetched_by.should == wolf_uid
      wolf_fp.fetched_directly.should be_true
    end

    it 'sets edge_count' do
      wolf_fp.create_friends_records_and_save_stats!
      wolf_fp.edge_count.should == 21
    end

    it 'generates a User and FacebookProfile record for every friend' do
      expect {
      expect {
        wolf_fp.create_friends_records_and_save_stats!
      }.to change(User,:count).by(2)
      }.to change(FacebookProfile,:count).by(2)
    end

    it 'sets name, image of friends' do
      wolf_fp.create_friends_records_and_save_stats!
      wei_fp = FacebookProfile.where(uid: weidong_uid).first

      wei_fp.name.should  == 'Weidong Yang'
      wei_fp.uid.should   == weidong_uid
      wei_fp.image.should == 'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/370434_563900754_1952612728_s.jpg'
    end

    # see notes at definition of get_friends_details
    #it 'adds photos posts tagged locations statuses likes feed to friends' do
    #  wolf_fp.create_friends_records_and_save_stats!
    #  wei_fp = FacebookProfile.where(uid: weidong_uid).first
    #  %w(photos posts tagged locations statuses likes feed).each do |attr|
    #    wei_fp.send(attr).should be_kind_of(Array)
    #    if attr != 'tagged'  # got no data for tagged--kind of rare
    #      wei_fp.send(attr).should_not be_empty
    #    end
    #  end
    #end

    it 'sets last_fetched_at; last_fetched_by to user through whom we got the data' do
      wolf_fp.create_friends_records_and_save_stats!
      wei = FacebookProfile.where(uid: weidong_uid).first

      wei.last_fetched_at.should == @now
      wei.last_fetched_by.should == wolf_fp.uid
      wei.fetched_directly.should be_false
    end

    it "includes friends array (as facebook_profile_uids) in direct user's record" do
      wolf_fp.facebook_profile_uids = []
      wolf_fp.create_friends_records_and_save_stats!
      wolf_fp.facebook_profile_uids.should =~ [lars_uid, weidong_uid]
    end

    it "friends arrays are many-to-many relationships with indirect users' (friends') records" do
      wolf_fp.facebook_profile_uids = []
      wolf_fp.create_friends_records_and_save_stats!

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

    it 'does NOT set token on friend records' do
      wolf_fp.create_friends_records_and_save_stats!
      wei = FacebookProfile.where(uid: weidong_uid).first
      wei.token.should be_nil
    end

    it 'clears friends that were attached before (i.e. overwrite on update)' do
      wolf_fp.facebook_profile_uids = [123,456]
      wolf_fp.create_friends_records_and_save_stats!

      wolf_fp.facebook_profile_uids.should_not include(123,456)
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
