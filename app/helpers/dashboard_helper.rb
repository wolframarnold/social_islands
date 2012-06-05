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
    loc_list = []
    if loc_array.present?
      num_loc = loc_array.length > 5 ? 5 : loc_array.length
      (0..num_loc).each do |i1|
        coord = Geocoder.coordinates(loc_array[i1][0])
        loc_list[i1] = {lat:coord[0], lng:coord[1], discription:i1, width:(10-i1), height:(10-i1), sidebar:i1}
      end
    end
    loc_list.to_json
  end

  def display_stats(profile)
    profile.user_stat.inject('') do |str,kv|
      str + "#{kv[0]}: #{kv[1]}" + '</br>'
    end.html_safe
  end

  # TODO: Have these contents come from a YAML file
  def popover_attrs(key)
    case key
      when :profile_authenticity
        {'data-original-title' => key.to_s.humanize,
         'data-content' => <<-STR
         The Authenticity Score tells us how much effort the user has invested into
         their profile over time. Variables that enter here include the number of friends,
         age of the profile. Higher scores here imply a greater relevance and
         confidence of the other scores.
         STR
        }
      when :trust_score
        {'data-original-title' => key.to_s.humanize,
         'data-content' => <<-STR
         The Trust Score is a measure of the real-world social engagement of the user
         with their community.
         STR
        }
      else
        raise "Unknown key #{key} for popover content"
    end
  end
end
