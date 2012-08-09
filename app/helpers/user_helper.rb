module UserHelper
  def user_image(user, options = {})
    options[:class] ||= "user_image"

    image_tag user.image.url(:large), options
  end

  def user_thumbnail(user, options = {})
    options[:class] ||= "user_thumbnail"

    image_tag user.image.url(:small), options
  end

  def user_thumbnail_tiny(user, options = {})
    options[:class] ||= "user_thumbnail_tiny"

    image_tag user.image.url(:small), options
  end

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
end
