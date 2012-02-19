module UserHelper

  # Returns true if this_user (or @this_user) is the currently logged_in user
  def current_user(this_user = nil)
    this_user ||= @this_user
    @user && this_user.id == @user.id 
  end
    
  def openid_logo
    image_tag "openid_small.png", :alt => t('user.login.openid_logo_alt'), :class => "openid_logo"
  end

  def openid_button(name, url)
    link_to_function(
      image_tag("#{name}.png", :alt => t("user.login.openid_providers.#{name}.alt")),
      "submitOpenidUrl('#{url}')",
      :title => t("user.login.openid_providers.#{name}.title")
    )
  end

  def contribution_terms_status(user)
    if not @this_user.terms_agreed.nil?
      return t 'user.view.ct accepted', :ago =>time_ago_in_words(@this_user.terms_agreed)
    elsif not @this_user.terms_seen?
      return t 'user.view.ct undecided'
    else
      return t 'user.view.ct declined'
    end
  end  
end
