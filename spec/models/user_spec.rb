# encoding: utf-8
require 'spec_helper'

describe User do

  context '.find_or_create_with_facebook_profile_by_uid' do

    context 'when User and FB Profile do not exist' do
      it 'creates a User with uid, name, image attributes' do
        expect {
        expect {
          user, fp = User.find_or_create_with_facebook_profile_by_uid(:uid => 123654, :name => 'Joe Smith', :image => 'http://example.com/joe')
          user.uid.should == '123654'
          user.name.should == 'Joe Smith'
          user.image.should == 'http://example.com/joe'
          fp.uid.should == '123654'
          fp.name.should == 'Joe Smith'
          fp.image.should == 'http://example.com/joe'
        }.to change(User, :count).by(1)
        }.to change(FacebookProfile, :count).by(1)
      end
    end

    context 'when User and FB Profile exist' do

      before do
        @fp = FactoryGirl.create(:facebook_profile)
        @user = @fp.user
      end

      it 'returns existing records' do
        user, fp = User.find_or_create_with_facebook_profile_by_uid(:uid => @fp.uid)
        user.should == @user
        fp.should == @fp
      end

      it 'updates name, image' do
        expect {
          User.find_or_create_with_facebook_profile_by_uid(:uid => @fp.uid, :name => 'Andy Miller', :image => 'http://example.com/andy')
        }.to change{[@user.name, @user.image, @fp.name, @fp.image]}.
          to(%w(Andy http://example.com/andy Andy http://example.com/andy))
      end

      it "won't override name or image with blank if not provided"
    end


  end

end