require 'spec_helper'

describe FacebookProfilesController do

  let!(:wolf_fp) { create(:wolf_facebook_profile) }

  before do
    controller.stub!(:current_facebook_profile).and_return(wolf_fp)
    session[:facebook_profile_id] = wolf_fp.to_param
  end

  context '#show' do
    before do
      Resque.should_receive(:enqueue).with(FacebookFetcher, wolf_fp.to_param, 'viz', push_to_web_graph_ready_url)
    end
    it 'pushes job on queue and sets @has_graph' do
      get :show
      assigns(:has_graph).should_not be_nil
    end
  end

  context "#label" do
    let!(:fb_graph) { create :facebook_graph, facebook_profile: wolf_fp }

    let(:label_attrs) { {group_index: 1, color: {r: 123, g: 234, b:56}}.with_indifferent_access }
    let(:update_attrs) { {label: {'1' => {group_index: '1', name: 'Highschool friends'}}} }

    it 'updates the label if it exists' do
      fb_graph.labels.push FacebookGraphLabel.new(label_attrs)
      fb_graph.reload.should have(1).labels
      expect {
        xhr :put, :label, update_attrs
      }.to_not change{fb_graph.reload.labels.count}
      fb_graph.labels.first.attributes.should include(label_attrs.merge(name: 'Highschool friends'))
    end

    it 'does not change other labels' do
      fb_graph.labels.push FacebookGraphLabel.new(label_attrs)
      fb_graph.labels.push FacebookGraphLabel.new(label_attrs.merge(group_index: 2, name: 'Coworkers'))
      fb_graph.save
      expect {
      expect {
        xhr :put, :label, update_attrs
      }.to change{fb_graph.reload.labels.first.name}.from(nil).to('Highschool friends')
      }.to_not change{fb_graph.reload.labels.last}
    end

    it 'does not overwrite the color if set' do
      fb_graph.labels.push FacebookGraphLabel.new(label_attrs)
      fb_graph.reload.should have(1).labels
      expect {
        xhr :put, :label, update_attrs
      }.to_not change{fb_graph.reload.labels.first.color}
    end

  end

  context "#graph" do
    let!(:fb_graph) { create :facebook_graph, facebook_profile: wolf_fp }

    it 'responds with application/gexf+xml content type' do
      get :graph
      response.content_type.should == 'application/gexf+xml'
      response.body.should match(%r{xmlns=.*"http://www.gexf.net/1.2draft})
    end
  end

end
