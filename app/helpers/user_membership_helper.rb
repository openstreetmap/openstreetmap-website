module UserMembershipHelper
  def membership_icons(user)
    UserMembership::ALL_MEMBERSHIPS.reduce("".html_safe) do |acc, elem|
      acc + " " + membership_icon(user, elem)
    end
  end

  def membership_icon(user, membership)
    if user.show_membership?(membership)
      image = "membership/#{membership}"
      alt = t("user.view.membership.#{membership}")
      title = t("user.view.membership.#{membership}")
      id = "badge-membership-#{membership}"
    end

    if image
      svg_icon = tag("source", :srcset => image_path("#{image}.svg"), :type => "image/svg+xml")
      png_icon = image_tag("#{image}.png", :srcset => image_path("#{image}.svg"), :size => "20x20", :border => 0, :alt => alt, :title => title, :id => id)
      icon = content_tag("picture", svg_icon + png_icon)
    end

    icon
  end
end
