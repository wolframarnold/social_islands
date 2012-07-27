module DashboardHelper

  def default_location
    [{lat: 38.7749295, lng: -122.4194155}, {lat: 37.8043, lng: -122.2711}].to_json
  end

  def default_circle
    [{lat: 38.7749295, lng: -122.4194155, radius:300000}].to_json
  end

  def user_location
    if @user.facebook_profile.info["location"]["name"].present?
      loc = Geocoder.coordinates(@user.facebook_profile.info["location"]["name"])
      [{lat:loc[0], lng:loc[1]}].to_json
    end
  end

  def user_location_with_circle
    if @user.facebook_profile.info["location"]["name"].present?
      loc = Geocoder.coordinates(@user.facebook_profile.info["location"]["name"])
      [{lat:loc[0], lng:loc[1], radius:10000}].to_json
    end
  end


  def friend_location
    loc_array = @user.facebook_profile.collect_friends_location_stats
    loc_array[0..5].reduce([]) do |coord_list, loc|
      coord = Geocoder.coordinates(loc[0])
      coord_list << {lat: coord[0], lng: coord[1]}
    end.to_json
  end

  def display_stats(profile)
    return '' if profile.user_stat.blank?
    profile.user_stat.inject('') do |str,kv|
      str + "#{kv[0]}: #{kv[1]}" + '</br>'
    end.html_safe
  end

  def popover_attrs(key)
    { 'data-original-title' => t("dashboard.#{key}.title") || key.to_s.humanize,
      'data-content' => t("dashboard.#{key}.content") }
  end

  def score_color_class(facebook_profile)
    return '' if facebook_profile.profile_authenticity.blank? || facebook_profile.profile_authenticity < 50
    return 'green'  if facebook_profile.trust_score > 65 # green
    return 'yellow' if facebook_profile.trust_score > 45 # yellow
    'red'
  end

  def best_picture_tag(fp)
    # try for about_me['picture'] which tends to be squre
    # if none, use 'image'
    image_tag(fp.about_me['picture'] || fp.image)
  end
end
