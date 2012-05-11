module ApplicationHelper

  def default_page_title
    "Social Islands - Discover Your Communities on Facebook"
  end

  def default_meta_description
    "Social Islands. Discover Your Communities on Facebook. Explore your network. Label your social islands."
  end

  def default_meta_keywords
    "Social Islands, discover communities, facebook, network visualization, explore network, label social islands, define groups"
  end

  def login_logout_links(opts={})
    if signed_in?
      link_to 'Sign Out', sign_out_path, opts.merge(title: 'Sign Out')
    else
      link_to 'Sign In', sign_in_path, opts.merge(title: 'Sign In')
    end
  end

  def sign_in_path
    '/auth/facebook'
  end

end
