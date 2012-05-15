require 'spec_helper'

describe FacebookProfile do

  let(:user) {FactoryGirl.create(:fb_user)}

  it 'saves name, uid, image from user' do
    fb = user.build_facebook_profile
    fb.save!
    fb.name.should == user.name
    fb.image.should == user.image
    fb.uid.should == user.uid
  end

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
      fp.should_receive(:get_all_friends).and_return(fp.friends)
      fp.info = {'name' => 'joe', 'email' => 'joe@example.com'}
      fp.should_receive(:execute_fb_batch_query)
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

end