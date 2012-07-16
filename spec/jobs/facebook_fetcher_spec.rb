require 'spec_helper'

describe FacebookFetcher do
  let!(:wolf_facebook_profile) { create(:wolf_facebook_profile, profile_authenticity: 63, trust_score: 88) }

  context "first-time profile" do
    it 'retrieves FB profile and network and pushes viz job on queue' do
      FacebookProfile.any_instance.should_receive(:import_profile_and_network!)

      Resque.should_receive(:push).with(
          'viz',
          hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [wolf_facebook_profile.to_param])
      )

      FacebookFetcher.perform(wolf_facebook_profile.to_param, 'viz')
    end
  end

  context 'scoring job' do
    it 'send post-back with scores to postback_url' do
      FacebookProfile.any_instance.should_receive(:import_profile_and_network!)
      FacebookProfile.any_instance.should_receive(:compute_all_scores!)
      stub_http_request(:post, "example.com/score")

      FacebookFetcher.perform(wolf_facebook_profile.to_param, 'scoring', 'http://example.com/score')

      a_request(:post, "example.com/score").
          with(body:    {facebook_id: wolf_facebook_profile.uid, profile_authenticity: 63, trust_score: 88},
               headers: {'Content-Type' => 'application/json'}).should have_been_made.once

    end

    it 'records facebook API error and sends postback with message, if received' do
      api_error = Koala::Facebook::APIError.new('type'=>'api exception', 'code'=> 234, 'message' => "234, something went wrong")
      FacebookProfile.any_instance.should_receive(:import_profile_and_network!).and_raise(api_error)
      stub_http_request(:post, "example.com/score")

      FacebookFetcher.perform(wolf_facebook_profile.to_param, 'scoring', 'http://example.com/score')

      wolf_facebook_profile.reload.facebook_api_error.should == 'api exception: 234, something went wrong'
      a_request(:post, "example.com/score").
          with(body:    {errors: {'base' => ['Facebook API Error--api exception: 234, something went wrong']}},
               headers: {'Content-Type' => 'application/json'}).should have_been_made.once

    end
  end

  context "repeat profile" do
    before do
      wolf_facebook_profile.update_attribute(:last_fetched_at, Time.now)
      FacebookProfile.any_instance.should_not_receive(:import_profile_and_network!)
    end

    context "graph doesn't exist" do
      it "doesn't make FB API calls again but puts viz job on queue" do
        Resque.should_receive(:push).with(
            'viz',
            hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [wolf_facebook_profile.to_param])
        )

        FacebookFetcher.perform(wolf_facebook_profile.to_param, 'viz')
      end
    end

    context "graph exists" do
      let!(:facebook_graph) { create(:facebook_graph, facebook_profile: wolf_facebook_profile) }

      it "doesn't make FB API calls nor pushes job on queue" do
        Resque.should_not_receive(:push)

        FacebookFetcher.perform(wolf_facebook_profile.to_param, 'viz')
      end
    end
  end

end