require "test_helper"

class UserRolesHelperTest < ActionView::TestCase
  attr_accessor :current_user

  def test_role_icon_normal
    self.current_user = create(:user)

    icon = role_icon(current_user, "moderator")
    assert_dom_equal "", icon

    icon = role_icon(current_user, "importer")
    assert_dom_equal "", icon

    icon = role_icon(create(:moderator_user), "moderator")
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "svg:root", :count => 1 do
      assert_dom "> title", :text => "This user is a moderator"
    end

    icon = role_icon(create(:importer_user), "importer")
    icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
    assert_dom icon_dom, "svg:root", :count => 1 do
      assert_dom "> title", :text => "This user is a importer"
    end
  end

  def test_role_icon_administrator
    self.current_user = create(:administrator_user)

    create(:user) do |user|
      icon = role_icon(user, "moderator")
      icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
      assert_dom icon_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='post']", :count => 1 do
        assert_dom "> svg", :count => 1 do
          assert_dom "> title", :text => "Grant moderator access"
        end
      end

      icon = role_icon(user, "importer")
      icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
      assert_dom icon_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='post']", :count => 1 do
        assert_dom "> svg", :count => 1 do
          assert_dom "> title", :text => "Grant importer access"
        end
      end
    end

    create(:moderator_user) do |user|
      icon = role_icon(user, "moderator")
      icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
      assert_dom icon_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='delete']", :count => 1 do
        assert_dom "> svg", :count => 1 do
          assert_dom "> title", :text => "Revoke moderator access"
        end
      end

      icon = role_icon(user, "importer")
      icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
      assert_dom icon_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='post']", :count => 1 do
        assert_dom "> svg", :count => 1 do
          assert_dom "> title", :text => "Grant importer access"
        end
      end
    end

    create(:importer_user) do |user|
      icon = role_icon(user, "moderator")
      icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
      assert_dom icon_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='post']", :count => 1 do
        assert_dom "> svg", :count => 1 do
          assert_dom "> title", :text => "Grant moderator access"
        end
      end

      icon = role_icon(user, "importer")
      icon_dom = Rails::Dom::Testing.html_document_fragment.parse(icon)
      assert_dom icon_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='delete']", :count => 1 do
        assert_dom "> svg", :count => 1 do
          assert_dom "> title", :text => "Revoke importer access"
        end
      end
    end
  end

  def test_role_icons_normal
    self.current_user = create(:user)

    icons = role_icons(current_user)
    assert_dom_equal "", icons

    icons = role_icons(create(:moderator_user))
    icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
    assert_dom icons_dom, "svg:root > title", :text => "This user is a moderator"

    icons = role_icons(create(:importer_user))
    icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
    assert_dom icons_dom, "svg:root > title", :text => "This user is a importer"

    icons = role_icons(create(:super_user))
    icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
    assert_dom icons_dom, "svg:root", :count => 3 do
      assert_dom "> title", :text => "This user is an administrator"
      assert_dom "> title", :text => "This user is a moderator"
      assert_dom "> title", :text => "This user is a importer"
    end
  end

  def test_role_icons_administrator
    self.current_user = create(:administrator_user)

    create(:user) do |user|
      icons = role_icons(user)
      icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
      assert_dom icons_dom, "a:root", :count => 3
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'administrator')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant administrator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant moderator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant importer access"
      end
    end

    create(:moderator_user) do |user|
      icons = role_icons(user)
      icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
      assert_dom icons_dom, "a:root", :count => 3
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'administrator')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant administrator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='delete']" do
        assert_dom "> svg > title", :text => "Revoke moderator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant importer access"
      end
    end

    create(:importer_user) do |user|
      icons = role_icons(user)
      icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
      assert_dom icons_dom, "a:root", :count => 3
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'administrator')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant administrator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='post']" do
        assert_dom "> svg > title", :text => "Grant moderator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='delete']" do
        assert_dom "> svg > title", :text => "Revoke importer access"
      end
    end

    create(:super_user) do |user|
      icons = role_icons(user)
      icons_dom = Rails::Dom::Testing.html_document_fragment.parse(icons)
      assert_dom icons_dom, "a:root", :count => 3
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'administrator')}'][data-method='delete']" do
        assert_dom "> svg > title", :text => "Revoke administrator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'moderator')}'][data-method='delete']" do
        assert_dom "> svg > title", :text => "Revoke moderator access"
      end
      assert_dom icons_dom, "a:root[href='#{user_role_path(user, 'importer')}'][data-method='delete']" do
        assert_dom "> svg > title", :text => "Revoke importer access"
      end
    end
  end
end
