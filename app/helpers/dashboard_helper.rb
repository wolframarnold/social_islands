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

  def tagged_location
    loc_hash = @user.facebook_profile.tagged_location_collection
    loc_list = []
    if loc_hash.present?
      i1=0
      loc_hash.each_key do |k|
        loc_list[i1]={lat:k["latitude"], lng:k["longitude"]}
        i1=i1+1
      end
    end
    loc_list.to_json
  end

  def user_location_with_circle
    return [].to_json if @user.facebook_profile.info["location"].blank?
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

  def score_background_color_attrs(facebook_profile)
    return {} if facebook_profile.try(:trust_score).nil?
    return {style: 'background-color: #5fff5f'} if facebook_profile.trust_score > 60 # green
    return {style: 'background-color: #ffff00'} if facebook_profile.trust_score > 40 # yellow
    {style: 'background-color: #ff3f3f'} # red
  end
end
