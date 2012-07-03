require 'spec_helper'

describe 'facebook_profiles/labels' do

  let!(:wolf_fp_graph) { create :facebook_graph }
  let!(:wolf_fp) { wolf_fp_graph.facebook_profile }

  before do
    wolf_fp_graph.labels.create(name: 'Work friends', group_index: 1, color: {g:123,b:234,r:98})
  end

  it 'renders correctly' do
    render partial: 'facebook_profiles/labels',
           locals: {facebook_profile: wolf_fp}
  end

end