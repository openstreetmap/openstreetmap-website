require "test_helper"

class UserRolesHelperTest < ActionView::TestCase
  attr_accessor :current_user

  def test_role_icon_normal
    self.current_user = create(:user)

    icon = role_icon(current_user, "moderator")
    assert_dom_equal "", icon

    icon = role_icon(create(:moderator_user), "moderator")
    expected = <<~HTML.delete("\n")
      <picture>
      <source srcset="/images/roles/moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/moderator.svg" border="0" alt="This user is a moderator" title="This user is a moderator" src="/images/roles/moderator.png" width="20" height="20" />
      </picture>
    HTML
    assert_dom_equal expected, icon
  end

  def test_role_icon_administrator
    self.current_user = create(:administrator_user)

    user = create(:user)
    icon = role_icon(user, "moderator")
    expected = <<~HTML.delete("\n")
      <a confirm="Are you sure you want to grant the role `moderator&#39; to the user `#{user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(user.display_name)}/role/moderator/grant">
      <picture>
      <source srcset="/images/roles/blank_moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/blank_moderator.svg" border="0" alt="Grant moderator access" title="Grant moderator access" src="/images/roles/blank_moderator.png" width="20" height="20" />
      </picture>
      </a>
    HTML
    assert_dom_equal expected, icon

    moderator_user = create(:moderator_user)
    icon = role_icon(moderator_user, "moderator")
    expected = <<~HTML.delete("\n")
      <a confirm="Are you sure you want to revoke the role `moderator&#39; from the user `#{moderator_user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(moderator_user.display_name)}/role/moderator/revoke">
      <picture>
      <source srcset="/images/roles/moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/moderator.svg" border="0" alt="Revoke moderator access" title="Revoke moderator access" src="/images/roles/moderator.png" width="20" height="20" />
      </picture>
      </a>
    HTML
    assert_dom_equal expected, icon
  end

  def test_role_icons_normal
    self.current_user = create(:user)

    icons = role_icons(current_user)
    assert_dom_equal "  ", icons

    icons = role_icons(create(:moderator_user))
    expected = "  " + <<~HTML.delete("\n")
      <picture>
      <source srcset="/images/roles/moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/moderator.svg" border="0" alt="This user is a moderator" title="This user is a moderator" src="/images/roles/moderator.png" width="20" height="20" />
      </picture>
    HTML
    assert_dom_equal expected, icons

    icons = role_icons(create(:super_user))
    expected = " " + <<~HTML.delete("\n")
      <picture>
      <source srcset="/images/roles/administrator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/administrator.svg" border="0" alt="This user is an administrator" title="This user is an administrator" src="/images/roles/administrator.png" width="20" height="20" />
      </picture>
       <picture>
      <source srcset="/images/roles/moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/moderator.svg" border="0" alt="This user is a moderator" title="This user is a moderator" src="/images/roles/moderator.png" width="20" height="20" />
      </picture>
    HTML
    assert_dom_equal expected, icons
  end

  def test_role_icons_administrator
    self.current_user = create(:administrator_user)

    user = create(:user)
    icons = role_icons(user)
    expected = " " + <<~HTML.delete("\n")
      <a confirm="Are you sure you want to grant the role `administrator&#39; to the user `#{user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(user.display_name)}/role/administrator/grant">
      <picture>
      <source srcset="/images/roles/blank_administrator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/blank_administrator.svg" border="0" alt="Grant administrator access" title="Grant administrator access" src="/images/roles/blank_administrator.png" width="20" height="20" />
      </picture>
      </a>
       <a confirm="Are you sure you want to grant the role `moderator&#39; to the user `#{user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(user.display_name)}/role/moderator/grant">
      <picture>
      <source srcset="/images/roles/blank_moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/blank_moderator.svg" border="0" alt="Grant moderator access" title="Grant moderator access" src="/images/roles/blank_moderator.png" width="20" height="20" />
      </picture>
      </a>
    HTML
    assert_dom_equal expected, icons

    moderator_user = create(:moderator_user)
    icons = role_icons(moderator_user)
    expected = " " + <<~HTML.delete("\n")
      <a confirm="Are you sure you want to grant the role `administrator&#39; to the user `#{moderator_user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(moderator_user.display_name)}/role/administrator/grant">
      <picture>
      <source srcset="/images/roles/blank_administrator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/blank_administrator.svg" border="0" alt="Grant administrator access" title="Grant administrator access" src="/images/roles/blank_administrator.png" width="20" height="20" />
      </picture>
      </a>
       <a confirm="Are you sure you want to revoke the role `moderator&#39; from the user `#{moderator_user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(moderator_user.display_name)}/role/moderator/revoke">
      <picture>
      <source srcset="/images/roles/moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/moderator.svg" border="0" alt="Revoke moderator access" title="Revoke moderator access" src="/images/roles/moderator.png" width="20" height="20" />
      </picture>
      </a>
    HTML
    assert_dom_equal expected, icons

    super_user = create(:super_user)
    icons = role_icons(super_user)
    expected = " " + <<~HTML.delete("\n")
      <a confirm="Are you sure you want to revoke the role `administrator&#39; from the user `#{super_user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(super_user.display_name)}/role/administrator/revoke">
      <picture>
      <source srcset="/images/roles/administrator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/administrator.svg" border="0" alt="Revoke administrator access" title="Revoke administrator access" src="/images/roles/administrator.png" width="20" height="20" />
      </picture>
      </a>
       <a confirm="Are you sure you want to revoke the role `moderator&#39; from the user `#{super_user.display_name}&#39;?" rel="nofollow" data-method="post" href="/user/#{ERB::Util.u(super_user.display_name)}/role/moderator/revoke">
      <picture>
      <source srcset="/images/roles/moderator.svg" type="image/svg+xml" />
      <img srcset="/images/roles/moderator.svg" border="0" alt="Revoke moderator access" title="Revoke moderator access" src="/images/roles/moderator.png" width="20" height="20" />
      </picture>
      </a>
    HTML
    assert_dom_equal expected, icons
  end
end
