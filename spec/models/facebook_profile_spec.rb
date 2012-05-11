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

end