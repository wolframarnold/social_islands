require 'spec_helper'

describe FacebookGraph do

  let!(:wolf_fp) { create :wolf_facebook_profile }

  # Note: These tests are not conclusive, because I can't verify
  # anything in the log that the facebook_graph record is queried,
  # not even in the low-level MongoDB log. So, while blank?
  # seems to return the correct result; I'm not sure how it works
  it 'can detect presence or absence without loading record' do
    wolf_fp.facebook_graph.blank?.should be_true
  end
  it 'can detect presence or absence without loading record 2' do
    wolf_fp.create_facebook_graph
    Mongoid::IdentityMap.clear
    wolf_fp.facebook_graph.blank?.should be_false
  end

end