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

end