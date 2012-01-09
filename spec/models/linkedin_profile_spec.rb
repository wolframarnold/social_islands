require 'spec_helper'

describe LinkedinProfile do

  let(:user) { User.create!(uid: '1234',provider: 'linkedin', name: 'Joe Smith') }

  context '#assign_attribute_hash' do

    let(:lp) { user.create_linkedin_profile! }

    it 'can serialize a LinkedIn::Mash' do
      names = {first_name: 'Joe', last_name: 'Smith'}
      lp.assign_attribute_hash(names)
      lp.save!

      lp.should respond_to(:first_name)
      lp.first_name.should == 'Joe'
      lp.should respond_to(:last_name)
      lp.last_name.should == 'Smith'
    end

    it 'can serialize an array of hashes' do
      positions = [LinkedIn::Mash.new(company: LinkedIn::Mash.new(industry:"Internet", name:"ABC"),
                                      id: 229314585, is_current: true,
                                      start_date: LinkedIn::Mash.new(month:5,year:2011),
                                      summary: "good stuff", title: "Consultant")]

      lp.assign_attribute_hash(positions: positions)
      lp.save!

      lp.positions.should be_kind_of(Array)
      lp.positions.length.should == 1
      lp.positions.first.should be_kind_of(Hash)
    end

    it 'changes the LinkedIn key "associations" to "professional_associations" due to a name clash with a mongo_mapper method' do
      mash = LinkedIn::Mash.new(associations: "Professional club\nSomething Else")
      lp.assign_attribute_hash mash
      lp.save!
      lp.professional_associations.should == mash.associations
    end
  end
end
