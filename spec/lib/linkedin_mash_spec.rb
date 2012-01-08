require 'spec_helper'

describe '#from_json' do

  it 'removes :all and :total and turns them into an array' do
    # raw linkedin data comes in with keys '_total' and 'values' that get mapped to 'total' and 'all' in the LinkedIn gem
    json = {twitter_accounts: {values: [{provider_account_id: '1234', provider_account_name: 'joesmith'}], _total: 1}}.to_json
    mash = LinkedIn::Mash.from_json(json)
    mash.should have_key(:twitter_accounts)
    mash.twitter_accounts.should be_kind_of(Array)
    mash.should == LinkedIn::Mash.new(twitter_accounts: [LinkedIn::Mash.new(provider_account_id: '1234', provider_account_name: 'joesmith')])
  end

end
