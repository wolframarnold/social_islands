require 'spec_helper'

describe FacebookFetcher do

  let!(:user) {FactoryGirl.create(:fb_user)}
  let!(:facebook_profile) {FactoryGirl.create(:facebook_profile, user: user)}

  it 'retrieves FB edges & friends and pushes viz job on queue' do
    FacebookProfile.any_instance.should_receive(:get_nodes_and_edges)

    Resque.should_receive(:push).with(
      'viz',
      hash_including(:class => 'com.socialislands.viz.VizWorker', :args => [user.to_param])
    )

    FacebookFetcher.perform(user.to_param)
  end
end