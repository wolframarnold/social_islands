require 'spec_helper'

describe FacebookFetcher do
  let!(:facebook_profile) {FactoryGirl.create(:facebook_profile, profile_maturity: 63, trust_score: 88)}

  context "first-time profile" do
    it 'retrieves FB profile and network and pushes viz job on queue' do
      FacebookProfile.any_instance.should_receive(:import_profile_and_network!)

      Resque.should_receive(:push).with(
          'viz',
          hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [facebook_profile.to_param])
      )

      FacebookFetcher.perform(facebook_profile.to_param, 'viz')
    end
  end

  context 'scoring job' do
    it 'send post-back with scores to postback_url' do
      FacebookProfile.any_instance.should_receive(:compute_trust_score)
      stub_http_request(:post, "example.com/score")

      FacebookFetcher.perform(facebook_profile.to_param, 'scoring', 'http://example.com/score')

      a_request(:post, "example.com/score").
          with(body:    {uid: facebook_profile.uid, profile_maturity: 63, trust_score: 88},
               headers: {'Content-Type' => 'application/json'}).should have_been_made.once

    end
  end

  context "repeat profile" do
    before do
      FacebookProfile.any_instance.should_not_receive(:import_profile_and_network!)
    end

    context "graph doesn't exist" do
      it "doesn't make FB API calls again but puts viz job on queue" do
        Resque.should_receive(:push).with(
            'viz',
            hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [user.to_param])
        )

        FacebookFetcher.perform(user.to_param, 'viz')
      end
    end

    context "graph exists" do
      let!(:facebook_graph) { create(:facebook_graph, facebook_profile: facebook_profile) }

      it "doesn't make FB API calls nor pushes job on queue" do
        Resque.should_not_receive(:push)

        FacebookFetcher.perform(user.to_param, 'viz')
      end
    end
  end

end