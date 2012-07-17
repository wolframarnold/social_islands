require '3scale/client'

module ThreeScale
  mattr_accessor :client
end

if Rails.env.production?
  ThreeScale.client = ThreeScale::Client.new(provider_key: ENV['THREE_SCALE_PROVIDER_KEY'])
elsif Rails.env.test?
  # In test environment, this should never be called, but we want to use mocks to
  # verify that the correct auth calls get made.
  ThreeScale.client = ThreeScale::Client.new(provider_key: ENV['THREE_SCALE_PROVIDER_KEY'] || '3scale_provider_key_dummy')
end