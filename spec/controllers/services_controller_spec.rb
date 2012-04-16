require 'spec_helper'

describe ServicesController do

  let!(:user) { FactoryGirl.create(:user) }

  before do
    controller.stub!(:current_user).and_return(user)
    session[:user_id] = user.id.to_s
  end

  context 'profile exists' do

    let!(:linkedin_profile) { user.create_linkedin_profile }

    it 'assigns @linkedin_profile' do
      get :linkedin

      linkedin_profile.should be_persisted
      assigns[:linkedin_profile].should == linkedin_profile
    end

  end

  context 'profile does not exist' do

    before do
      LinkedinProfile.any_instance.should_receive(:fetch_profile)
    end

    it 'creates a new linkedin_profile instance from the current user' do
      expect {
        get :linkedin
      }.to change(LinkedinProfile,:count)

      assigns[:linkedin_profile].should_not be_nil
      assigns[:linkedin_profile].should be_persisted
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
