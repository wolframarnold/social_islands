require 'spec_helper'

describe ServicesController do

  let!(:user) { FactoryGirl.create(:fb_user) }

  before do
    controller.stub!(:current_user).and_return(user)
    session[:user_id] = user.id.to_s
  end

  context 'profile exists' do

    let!(:facebook_profile) { user.create_facebook_profile }

    it 'assigns @facebook_profile' do
      get :facebook

      facebook_profile.should be_persisted
      assigns[:facebook_profile].should == facebook_profile
    end

  end

  context 'profile does not exist' do

    before do
      FacebookProfile.any_instance.should_receive(:get_nodes_and_edges)
    end

    it 'creates a new facebook_profile instance from the current user' do
      expect {
        get :facebook
      }.to change(FacebookProfile,:count)

      assigns[:facebook_profile].should_not be_nil
      assigns[:facebook_profile].should be_persisted
    end
  end

  context "#facebook_label" do
    let!(:fb_profile) {FactoryGirl.create(:facebook_profile, user: user)}

    it 'updates/adds the label only' do

      expect {
        xhr :post, :facebook_label, {groupId: 12, labelText: 'Highschool friends'}
      }.to change{fb_profile.reload.labels}.from({}).to({'12' => 'Highschool friends'})
    end

  end

end
