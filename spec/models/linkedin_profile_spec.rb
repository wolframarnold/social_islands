require 'spec_helper'

describe LinkedinProfile do

  let(:user) { User.create!(uid: '1234',provider: 'linkedin', name: 'Joe Smith') }

  it 'can serialize a LinkedIn::Mash' do
    mash = [LinkedIn::Mash.new(company: LinkedIn::Mash.new(industry:"Internet", name:"ABC"),
                              id: 229314585, is_current: true,
                              start_date: LinkedIn::Mash.new(month:5,year:2011),
                              summary:"good stuff", title:"Consultant")]

    lp = user.create_linkedin_profile!
    lp[:positions] = mash

    lp.save!

    lp.reload
    lp.positions.should be_kind_of(Array)
    lp.positions.length.should == 1
    lp.positions.first.should be_kind_of(Hash)

  end

end
