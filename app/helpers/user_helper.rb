module UserHelper
  # User images

  def user_image(user, options = {})
    options[:class] ||= "user_image"

    if user.use_gravatar
      user_gravatar_tag(user, options)
    else
      image_tag user.image.url(:large), options
    end
  end

  def user_thumbnail(user, options = {})
    options[:class] ||= "user_thumbnail"

    if user.use_gravatar
      user_gravatar_tag(user, options)
    else
      image_tag user.image.url(:small), options
    end
  end

  def user_thumbnail_tiny(user, options = {})
    options[:class] ||= "user_thumbnail_tiny"

    if user.use_gravatar
      user_gravatar_tag(user, options)
    else
      image_tag user.image.url(:small), options
    end
  end

  # OpenID support

  def openid_logo
    image_tag "openid_small.png", :alt => t('user.login.openid_logo_alt'), :class => "openid_logo"
  end

  def openid_button(name, url)
    link_to(
      image_tag("#{name}.png", :alt => t("user.login.openid_providers.#{name}.alt")),
      "#",
      :class => "openid_button", :data => { :url => url },
      :title => t("user.login.openid_providers.#{name}.title")
    )
  end

  # Gravatar support

  # See http://en.gravatar.com/site/implement/images/ for details.
  def user_gravatar_url(user, options = {})
    options = {:size => 80}.merge! options
    hash = Digest::MD5::hexdigest(user.email.downcase)
    url = "http://www.gravatar.com/avatar/#{hash}.jpg?s=#{options[:size]}"
  end

  def user_gravatar_tag(user, options = {})
    url = user_gravatar_url(user, options)
    options.delete(:size)
    image_tag url, options
  end
end
