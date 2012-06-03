# encoding: utf-8

require 'spec_helper'

describe FacebookProfile do

  let!(:user) {FactoryGirl.create(:fb_user)}

  context 'detects attributes without loading them' do
    before do
      @fb = FactoryGirl.create(:facebook_profile, user: user)
      Mongoid::IdentityMap.clear  # prevent cache from holding graph
      @fb = FacebookProfile.find(@fb.to_param)
      @fb.graph.should be_nil
    end

    it 'graph' do
      expect {
        @fb.should have_graph
      }.to_not change(@fb, :graph)
    end

    # Mongoid removed more than one $ne clause -- not sure this is a Mongoid bug or a native MongoDB limitation
    # couldn't figure out how to test for both conditions easily $nin => [nil, ''] didn't seem to work either.
    #it 'detects "" as not present' do
    #  @fb.set(:graph, '')
    #  Mongoid::IdentityMap.clear  # prevent cache from holding graph
    #  @fb.should_not have_graph
    #end

    it 'detects nil as not present' do
      @fb.unset(:graph)
      Mongoid::IdentityMap.clear  # prevent cache from holding graph
      @fb.should_not have_graph
    end

    it 'edges' do
      expect {
        @fb.should have_graph
      }.to_not change(@fb, :edges)
    end
  end

  context 'photo_engagements' do

    it { should respond_to(:photo_engagements)}

    it { should respond_to(:compute_photo_engagements)}

  end

  context 'FB request batching' do
    let(:fp) { FactoryGirl.create(:facebook_profile, user: user) }

    before do
      fp.info = {'name' => 'joe', 'uid' => '222222'}
      fp.should_receive(:execute_fb_batch_query).twice
    end

    it 'batches all requests' do
      fp.get_profile_and_network_graph!
      batched_attrs = fp.instance_variable_get(:@batched_attributes)
      batched_attrs.should include(attr: :edges, chunked: true)
      batched_attrs.should include(attr: :photos, chunked: false)
      batched_attrs.should include(attr: :image, chunked: false)
      batched_attrs.should include(attr: :posts, chunked: false)
      batched_attrs.should include(attr: :tagged, chunked: false)
      batched_attrs.should include(attr: :locations, chunked: false)
      batched_attrs.should include(attr: :statuses, chunked: false)
      batched_attrs.should include(attr: :info, chunked: false)
    end

  end

  context '.find_or_create_by_token' do

    context 'FBProfile and User records exist' do
      let!(:fb_profile) { FactoryGirl.create(:facebook_profile, user: user) }

      context 'token matches' do

        it 'returns record' do
          FacebookProfile.find_or_create_by_token(fb_profile.token).should == fb_profile
        end
        it 'does not create a new record' do
          expect {
            FacebookProfile.find_or_create_by_token(fb_profile.token)
          }.should_not change(FacebookProfile,:count)
        end
      end
      context 'token does not match' do
        before do
          Koala::Facebook::API.any_instance.should_receive(:get_object).
              with('me', fields: 'id').
              and_return('id'=>fb_profile.uid)
        end
        it 'finds record by UID' do
          FacebookProfile.find_or_create_by_token(fb_profile.token+'123').should == fb_profile
        end
        it 'does not create a new record' do
          expect {
            FacebookProfile.find_or_create_by_token(fb_profile.token+'123')
          }.should_not change(FacebookProfile,:count)
        end
        it 'updates token' do
          old_token = fb_profile.token
          expect {
            FacebookProfile.find_or_create_by_token(fb_profile.token+'123')
          }.should change{fb_profile.user.reload.token}.from(old_token).to(old_token+'123')
        end
      end
    end

    context 'User record exists but FBProfile does not' do
      it 'creates a new FBProfile record' do
        expect {
          fp = FacebookProfile.find_or_create_by_token(user.token)
          fp.user.should == user
        }.to change(FacebookProfile,:count).by(1)
      end
      it 'does not create a new User record' do
        expect {
          FacebookProfile.find_or_create_by_token(user.token)
        }.to_not change(User,:count)
      end
    end

    context 'neither FBProfile nor User record does not exist' do
      before do
        Koala::Facebook::API.any_instance.should_receive(:get_object).
            with('me', fields: 'id').
            and_return('id'=>'7654321')
      end
      it 'creates a new record' do
        expect {
          FacebookProfile.find_or_create_by_token('zxcvlkjh768')
        }.to change(FacebookProfile,:count).by(1)
      end
      it 'creates a new user' do
        expect {
          fp = FacebookProfile.find_or_create_by_token('zxcvlkjh768')
          fp.user.should_not be_nil
          fp.user.uid.should == '7654321'
        }.to change(User,:count).by(1)
      end
    end

  end

  context '#collect_friends_location_stats' do

    it 'returns locations map from friends sorted by frequency' do
      exp = [["San Francisco, California, United States", 252], ["Oakland, California, United States", 48],
             ["Berkeley, California, United States", 16], ["New York, New York, United States", 14],
             ["Los Angeles, California, United States", 13], ["San Jose, California, United States", 12],
             ["Fremont, California, United States", 6], ["Chicago, Illinois, United States", 6],
             ["Pleasanton, California, United States", 6], ["Mountain View, California, United States", 4],
             ["Alameda, California, United States", 4], ["Santa Clara, California, United States", 3],
             ["Taipei, Taiwan", 3], ["Paris, France", 3], ["San Mateo, California, United States", 3],
             ["Brussels, Belgium", 3], ["Sacramento, California, United States", 3],
             ["Boulder, Colorado, United States", 3], ["San Rafael, California, United States", 3],
             ["Portland, Oregon, United States", 3], ["Brooklyn, New York, United States", 2],
             ["Eugene, Oregon, United States", 2], ["Emeryville, California, United States", 2],
             ["Dublin, California, United States", 2], ["Berlin, Germany", 2],
             ["Tel Aviv, Israel", 2], ["Palo Alto, California, United States", 2],
             ["Foster City, California, United States", 2], ["Boston, Massachusetts, United States", 2],
             ["Concord, California, United States", 2], ["Menlo Park, California, United States", 2],
             ["Washington, District of Columbia, United States", 1], ["Salzburg, Austria", 1], ["Daejeon, Korea", 1],
             ["Las Vegas, Nevada, United States", 1], ["Ho Chi Minh City, Vietnam", 1], ["Marburg, Germany", 1],
             ["Neustrelitz", 1], ["Brisbane, California, United States", 1], ["Moscow, Russia", 1],
             ["Redwood Shores, California, United States", 1], ["Ljubljana, Slovenia", 1],
             ["Coogee, New South Wales, Australia", 1], ["San Antonio, Texas, United States", 1],
             ["Castro Valley, California, United States", 1], ["Austin, Texas, United States", 1],
             ["Bellevue, Washington, United States", 1], ["Springfield, Oregon, United States", 1],
             ["Jersey City, New Jersey, United States", 1], ["Santa Barbara, California, United States", 1],
             ["Culver City, California, United States", 1], ["San Carlos, California, United States", 1],
             ["Sendai-shi, Miyagi, Japan", 1], ["Pleasant Hill, California, United States", 1],
             ["Salt Lake City, Utah, United States", 1], ["Suwon", 1], ["Fort Worth, Texas, United States", 1],
             ["Geneva, Switzerland", 1], ["Ann Arbor, Michigan, United States", 1],
             ["Walnut Creek, California, United States", 1], ["Philadelphia, Pennsylvania, United States", 1],
             ["Sunnyvale, California, United States", 1], ["Saarbrücken", 1], ["Lima, Peru", 1],
             ["Phoenix, Arizona, United States", 1], ["Willemstad, Netherlands Antilles", 1], ["Mesagne", 1],
             ["Long Beach, California, United States", 1], ["Cerritos, California, United States", 1],
             ["Mexico City, Mexico", 1], ["Nevada City, California, United States", 1], ["Ga`Aton, Hazafon, Israel", 1],
             ["Stamford, Connecticut, United States", 1], ["Groningen", 1], ["Athens, Greece", 1], ["Beijing, China", 1],
             ["Salem, Massachusetts, United States", 1], ["Uppsala, Sweden", 1], ["Munich, Germany", 1],
             ["Kingston, Jamaica", 1], ["Corte Madera, California, United States", 1],
             ["Richmond, California, United States", 1], ["Astoria, New York, United States", 1],
             ["Guadalajara, Jalisco", 1], ["Kensington, California, United States", 1], ["Twin cities, United States", 1],
             ["Zaragoza, Spain", 1], ["Nashville, Tennessee, United States", 1], ["Yopal, Casanare", 1],
             ["Lancaster, Pennsylvania, United States", 1], ["London, United Kingdom", 1],
             ["South San Francisco, California, United States", 1], ["Livermore, California, United States", 1],
             ["Milan, Italy", 1], ["Hayward, California, United States", 1], ["Pahoa, Hawaii, United States", 1],
             ["Pisticci, Basilicata, Italy", 1], ["Healdsburg, California, United States", 1],
             ["Charlottesville, Virginia, United States", 1], ["Raleigh, North Carolina, United States", 1],
             ["San Miguel de Allende, Guanajuato", 1], ["El Sobrante, California, United States", 1],
             ["Stockholm, Sweden", 1], ["La Jolla, California, United States", 1], ["São Paulo, Brazil", 1],
             ["Salvador, Bahia, Brazil", 1], ["Hong Kong", 1], ["Atherton, California, United States", 1],
             ["Neuville-sur-Saône", 1]]

      wei_fp = FactoryGirl.create(:wei_fb_profile)

      wei_fp.collect_friends_location_stats.should == exp
    end

  end

end