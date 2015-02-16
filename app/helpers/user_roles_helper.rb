module UserRolesHelper
  def role_icons(user)
    UserRole::ALL_ROLES.reduce("".html_safe) { |s, r| s + " " + role_icon(user, r) }
  end

  def role_icon(user, role)
    if @user && @user.administrator?
      if user.has_role?(role)
        image = "roles/#{role}.png"
        alt = t("user.view.role.revoke.#{role}")
        title = t("user.view.role.revoke.#{role}")
        url = revoke_role_path(:display_name => user.display_name, :role => role)
        confirm = t("user_role.revoke.are_you_sure", :name => user.display_name, :role => role)
      else
        image = "roles/blank_#{role}.png"
        alt = t("user.view.role.grant.#{role}")
        title = t("user.view.role.grant.#{role}")
        url = grant_role_path(:display_name => user.display_name, :role => role)
        confirm = t("user_role.grant.are_you_sure", :name => user.display_name, :role => role)
      end
    elsif user.has_role?(role)
      image = "roles/#{role}.png"
      alt = t("user.view.role.#{role}")
      title = t("user.view.role.#{role}")
    end

    if image
      icon = image_tag(image, :size => "20x20", :border => 0, :alt => alt, :title => title)

      if url
        icon = link_to(icon, url, :method => :post, :confirm => confirm)
      end
    end

    icon
  end
end
