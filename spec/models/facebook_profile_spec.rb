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

  context "Map Reduce Photo Engagement Stats" do

    before do
      @fb_profile = FactoryGirl.create(:fb_profile)
    end

  end

end