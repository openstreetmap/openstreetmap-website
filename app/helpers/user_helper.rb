module UserHelper
  def openid_logo
    image_tag "openid_small.png", :alt => t('user.login.openid_logo_alt'), :class => "openid_logo"
  end

  def openid_button(name, url)
    link_to_function(
      image_tag("#{name}.png", :alt => t("user.login.openid_providers.#{name}.alt")),
      nil,
      :title => t("user.login.openid_providers.#{name}.title")
    ) do |page|
      page[:login_form][:user_openid_url][:value] = url
      page[:login_form].submit()
    end
  end
end
