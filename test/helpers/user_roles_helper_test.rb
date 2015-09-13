require "test_helper"

class UserRolesHelperTest < ActionView::TestCase
  fixtures :users, :user_roles

  def test_role_icon_normal
    @user = users(:normal_user)

    icon = role_icon(users(:normal_user), "moderator")
    assert_dom_equal "", icon

    icon = role_icon(users(:moderator_user), "moderator")
    assert_dom_equal '<picture><source srcset="/images/roles/moderator.svg" type="image/svg+xml" /><img border="0" alt="This user is a moderator" title="This user is a moderator" src="/images/roles/moderator.png" width="20" height="20" /></picture>', icon
  end

  def test_role_icon_administrator
    @user = users(:administrator_user)

    icon = role_icon(users(:normal_user), "moderator")
    assert_dom_equal '<a confirm="Are you sure you want to grant the role `moderator&#39; to the user `test&#39;?" rel="nofollow" data-method="post" href="/user/test/role/moderator/grant"><picture><source srcset="/images/roles/blank_moderator.svg" type="image/svg+xml" /><img border="0" alt="Grant moderator access" title="Grant moderator access" src="/images/roles/blank_moderator.png" width="20" height="20" /></picture></a>', icon

    icon = role_icon(users(:moderator_user), "moderator")
    assert_dom_equal '<a confirm="Are you sure you want to revoke the role `moderator&#39; from the user `moderator&#39;?" rel="nofollow" data-method="post" href="/user/moderator/role/moderator/revoke"><picture><source srcset="/images/roles/moderator.svg" type="image/svg+xml" /><img border="0" alt="Revoke moderator access" title="Revoke moderator access" src="/images/roles/moderator.png" width="20" height="20" /></picture></a>', icon
  end

  def test_role_icons_normal
    @user = users(:normal_user)

    icons = role_icons(users(:normal_user))
    assert_dom_equal "  ", icons

    icons = role_icons(users(:moderator_user))
    assert_dom_equal '  <picture><source srcset="/images/roles/moderator.svg" type="image/svg+xml" /><img border="0" alt="This user is a moderator" title="This user is a moderator" src="/images/roles/moderator.png" width="20" height="20" /></picture>', icons

    icons = role_icons(users(:super_user))
    assert_dom_equal ' <picture><source srcset="/images/roles/administrator.svg" type="image/svg+xml" /><img border="0" alt="This user is an administrator" title="This user is an administrator" src="/images/roles/administrator.png" width="20" height="20" /></picture> <picture><source srcset="/images/roles/moderator.svg" type="image/svg+xml" /><img border="0" alt="This user is a moderator" title="This user is a moderator" src="/images/roles/moderator.png" width="20" height="20" /></picture>', icons
  end

  def test_role_icons_administrator
    @user = users(:administrator_user)

    icons = role_icons(users(:normal_user))
    assert_dom_equal ' <a confirm="Are you sure you want to grant the role `administrator&#39; to the user `test&#39;?" rel="nofollow" data-method="post" href="/user/test/role/administrator/grant"><picture><source srcset="/images/roles/blank_administrator.svg" type="image/svg+xml" /><img border="0" alt="Grant administrator access" title="Grant administrator access" src="/images/roles/blank_administrator.png" width="20" height="20" /></picture></a> <a confirm="Are you sure you want to grant the role `moderator&#39; to the user `test&#39;?" rel="nofollow" data-method="post" href="/user/test/role/moderator/grant"><picture><source srcset="/images/roles/blank_moderator.svg" type="image/svg+xml" /><img border="0" alt="Grant moderator access" title="Grant moderator access" src="/images/roles/blank_moderator.png" width="20" height="20" /></picture></a>', icons

    icons = role_icons(users(:moderator_user))
    assert_dom_equal ' <a confirm="Are you sure you want to grant the role `administrator&#39; to the user `moderator&#39;?" rel="nofollow" data-method="post" href="/user/moderator/role/administrator/grant"><picture><source srcset="/images/roles/blank_administrator.svg" type="image/svg+xml" /><img border="0" alt="Grant administrator access" title="Grant administrator access" src="/images/roles/blank_administrator.png" width="20" height="20" /></picture></a> <a confirm="Are you sure you want to revoke the role `moderator&#39; from the user `moderator&#39;?" rel="nofollow" data-method="post" href="/user/moderator/role/moderator/revoke"><picture><source srcset="/images/roles/moderator.svg" type="image/svg+xml" /><img border="0" alt="Revoke moderator access" title="Revoke moderator access" src="/images/roles/moderator.png" width="20" height="20" /></picture></a>', icons

    icons = role_icons(users(:super_user))
    assert_dom_equal ' <a confirm="Are you sure you want to revoke the role `administrator&#39; from the user `super&#39;?" rel="nofollow" data-method="post" href="/user/super/role/administrator/revoke"><picture><source srcset="/images/roles/administrator.svg" type="image/svg+xml" /><img border="0" alt="Revoke administrator access" title="Revoke administrator access" src="/images/roles/administrator.png" width="20" height="20" /></picture></a> <a confirm="Are you sure you want to revoke the role `moderator&#39; from the user `super&#39;?" rel="nofollow" data-method="post" href="/user/super/role/moderator/revoke"><picture><source srcset="/images/roles/moderator.svg" type="image/svg+xml" /><img border="0" alt="Revoke moderator access" title="Revoke moderator access" src="/images/roles/moderator.png" width="20" height="20" /></picture></a>', icons
  end
end
