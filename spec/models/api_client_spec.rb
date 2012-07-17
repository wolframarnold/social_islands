require 'spec_helper'

describe ApiClient do

  context '.setup_if_missing' do

    before :all do
      # To refresh the original server response with VCR, set these two
      # environment variables at the time of running it.
      # ENV['THREE_SCALE_PROVIDER_KEY']  -- handled in 3scale.rb initializer
      # ENV['APP_ID']
      @app_id = ENV['APP_ID'] || '66b53220'
      VCR.insert_cassette('3scale/rubyfocus_developer_app', allow_playback_repeats: true)
    end

    after :all do
      VCR.eject_cassette('3scale/rubyfocus_developer_app')
    end

    it 'creates a record by APP ID if it does not exit' do
      api_client = nil
      expect {
        api_client = ApiClient.setup_if_missing!(@app_id)
      }.to change(ApiClient, :count).by(1)
      api_client.postback_domain.should == 'localhost:3000'
      api_client.name.should == 'Rubyfocus developer app'
      api_client.app_id.should == '66b53220'
    end

    it 'queries name and postback domain from 3Scale' do
      ApiClient.setup_if_missing!(@app_id)

      a_request(:get, 'https://trustcc-admin.3scale.net/admin/api/applications/find.xml').
          with(query: {provider_key: ThreeScale.client.provider_key, app_id: @app_id}).
          should have_been_made.once
    end

  end

end