require 'spec_helper'

describe FacebookFetcher do

  let!(:user) {FactoryGirl.create(:fb_user)}

  context 'scoring job' do
    let!(:facebook_profile) {FactoryGirl.create(:facebook_profile, graph: nil, user: user,
                                                profile_maturity: 63, trust_score: 88)}

    before do
      FacebookProfile.any_instance.should_receive(:compute_trust_score)
    end

    it 'send post-back with scores to postback_url' do
      stub_http_request(:post, "example.com/score")

      FacebookFetcher.perform(user.to_param, 'scoring', 'http://example.com/score')

      a_request(:post, "example.com/score").
          with(body:    {uid: facebook_profile.uid, profile_maturity: 63, trust_score: 88},
               headers: {'Content-Type' => 'application/json'}).should have_been_made.once

    end
  end

  context "first-time profile" do
    let!(:facebook_profile) {FactoryGirl.create(:facebook_profile, graph: nil, edges: nil, friends: nil, user: user)}

    it 'retrieves FB edges & friends and pushes viz job on queue' do
      FacebookProfile.any_instance.should_receive(:get_profile_and_network_graph!)

      Resque.should_receive(:push).with(
        'viz',
        hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [user.to_param])
      )

      FacebookFetcher.perform(user.to_param, 'viz')
    end
  end

  context "repeat profile" do

    it "doesn't retrieve edges, friends if they exist but puts viz job on queue" do
      facebook_profile = FactoryGirl.create(:facebook_profile, graph: nil,user: user)
      facebook_profile.should have_edges
      FacebookProfile.any_instance.should_not_receive(:get_profile_and_network_graph!)

      Resque.should_receive(:push).with(
          'viz',
          hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [user.to_param])
      )

      FacebookFetcher.perform(user.to_param, 'viz')
    end

    it "doesn't retrieve edges, friends if they exist nor puts viz job on queue if graph exists" do
      facebook_profile = FactoryGirl.create(:facebook_profile, user: user)
      facebook_profile.should have_edges
      facebook_profile.should have_graph
      FacebookProfile.any_instance.should_not_receive(:get_profile_and_network_graph)

      Resque.should_not_receive(:push)

      FacebookFetcher.perform(user.to_param, 'viz')
    end
  end
end