module UserRolesHelper
  def role_icons(user)
    safe_join(UserRole::ALL_ROLES.filter_map { |role| role_icon(user, role) }, " ")
  end

  def role_icon(user, role)
    if current_user&.administrator?
      if user.role?(role)
        link_to role_icon_svg_tag(role, false, t("users.show.role.revoke.#{role}")),
                user_role_path(user, role),
                :method => :delete,
                :data => { :confirm => t("user_role.revoke.are_you_sure", :name => user.display_name, :role => role) }
      else
        link_to role_icon_svg_tag(role, true, t("users.show.role.grant.#{role}")),
                user_role_path(user, role),
                :method => :post,
                :data => { :confirm => t("user_role.grant.are_you_sure", :name => user.display_name, :role => role) }
      end
    elsif user.role?(role)
      role_icon_svg_tag(role, false, t("users.show.role.#{role}"))
    end
  end

  def role_icon_svg_tag(role, blank, title, **options)
    role_colors = {
      "administrator" => "#f69e42",
      "moderator" => "#447eff",
      "importer" => "#38e13a"
    }
    color = role_colors[role] || "currentColor"

    path_data = "M 10,2 8.125,8 2,8 6.96875,11.71875 5,18 10,14 15,18 13.03125,11.71875 18,8 11.875,8 10,2 z"
    tag.svg(:width => 20, :height => 20, **options) do
      concat tag.title(title)
      concat tag.path(:d => path_data,
                      :fill => blank ? "none" : color,
                      :stroke => color,
                      "stroke-width" => blank ? 1.5 : 2,
                      "stroke-linejoin" => "round")
    end
  end
end
