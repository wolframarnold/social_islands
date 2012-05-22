module FacebookFixtureHelpers

  def fb_info_response
    @info_response ||= JSON.parse(File.read(File.expand_path('../../fixtures/facebook_info_response.json', __FILE__)))
  end

end