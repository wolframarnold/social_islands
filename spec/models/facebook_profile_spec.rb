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

end