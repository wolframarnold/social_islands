module FacebookHelper

  def css_rgb_from_rgb_hash(rgb_hash)
    rgb_triplet = %w(r g b).map{|c| rgb_hash[c] }.join(',')
    "rgb(#{rgb_triplet})"
  end

end
