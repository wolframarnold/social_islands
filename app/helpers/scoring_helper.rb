module ScoringHelper

  def user_image
    if @facebook_profile.image.present?
      image_tag @facebook_profile.image
    else
      image_tag 'dummy_user_128.png'
    end
  end

  def user_name
    if @facebook_profile.name.present?
      @facebook_profile.name
    else
      "UID #{@facebook_profile.uid}"
    end
  end

end
