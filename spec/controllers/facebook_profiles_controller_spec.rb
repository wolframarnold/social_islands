require 'spec_helper'

describe FacebookProfilesController do

  let!(:facebook_profile) { create(:facebook_profile) }

  before do
    controller.stub!(:current_facebook_profile).and_return(facebook_profile)
    session[:facebook_profile_id] = facebook_profile.to_param
  end

  context '#show' do
    before do
      Resque.should_receive(:enqueue).with(FacebookFetcher, facebook_profile.to_param, 'viz')
    end
    it 'pushes job on queue and sets @has_graph' do
      get :show
      assigns(:has_graph).should_not be_nil
    end
  end

  context "#label" do
    let!(:fb_profile) {FactoryGirl.create(:facebook_profile, user: user)}
    let(:label_attrs) { {group_index: 1, color: {r: 123, g: 234, b:56}}.with_indifferent_access }
    let(:update_attrs) { {label: {'1' => {group_index: '1', name: 'Highschool friends'}}} }

    it 'updates the label if it exists' do
      fb_profile.labels.push Label.new(label_attrs)
      fb_profile.reload.should have(1).labels
      expect {
        xhr :put, :label, update_attrs
      }.to_not change{fb_profile.reload.labels.count}
      fb_profile.labels.first.attributes.should include(label_attrs.merge(name: 'Highschool friends'))
    end

    it 'does not change other labels' do
      fb_profile.labels.push Label.new(label_attrs)
      fb_profile.labels.push Label.new(label_attrs.merge(group_index: 2, name: 'Coworkers'))
      fb_profile.save
      expect {
      expect {
        xhr :put, :label, update_attrs
      }.to change{fb_profile.reload.labels.first.name}.from(nil).to('Highschool friends')
      }.to_not change{fb_profile.reload.labels.last}
    end

    it 'does not overwrite the color if set' do
      fb_profile.labels.push Label.new(label_attrs)
      fb_profile.reload.should have(1).labels
      expect {
        xhr :put, :label, update_attrs
      }.to_not change{fb_profile.reload.labels.first.color}
    end

  end

  context "#graph" do
    let!(:fb_profile) {FactoryGirl.create(:facebook_profile, user: user)}

    it 'responds with application/gexf+xml content type' do
      get :graph
      response.content_type.should == 'application/gexf+xml'
      response.body.should match(%r{xmlns=.*"http://www.gexf.net/1.2draft})
    end
  end

end
