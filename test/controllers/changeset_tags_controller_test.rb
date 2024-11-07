require "test_helper"

class ChangesetTagsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/changeset/1/tags", :method => :get },
      { :controller => "changeset_tags", :action => "show", :changeset_id => "1" }
    )
  end

  def test_show_success
    changeset = create(:changeset)
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(changeset)
    assert_response :success

    assert_dom ".content-body" do
      assert_dom "h2", :text => "Changeset: #{changeset.id}" do
        assert_dom "a[href='#{changeset_path(changeset)}']"
      end

      assert_dom "a[href='#{user_path(changeset.user)}']"
    end
  end

  def test_show_success_1_tag
    changeset = create(:changeset)
    create(:changeset_tag, :changeset => changeset, :k => "tested-tag-key", :v => "tested-tag-value")
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(changeset)
    assert_response :success

    assert_dom ".content-body" do
      assert_dom "tbody tr", :count => 1 do |rows|
        check_tag_table_row rows[0], changeset, "tested-tag-key", "tested-tag-value"
      end
    end
  end

  def test_show_success_2_tags
    changeset = create(:changeset)
    create(:changeset_tag, :changeset => changeset, :k => "tested-1st-tag-key", :v => "tested-1st-tag-value")
    create(:changeset_tag, :changeset => changeset, :k => "tested-2nd-tag-key", :v => "tested-2nd-tag-value")
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(changeset)
    assert_response :success

    assert_dom ".content-body" do
      assert_dom "tbody tr", :count => 2 do |rows|
        check_tag_table_row rows[0], changeset, "tested-1st-tag-key", "tested-1st-tag-value"
        check_tag_table_row rows[1], changeset, "tested-2nd-tag-key", "tested-2nd-tag-value"
      end
    end
  end

  def test_show_fail_no_changeset
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(999111)
    assert_response :not_found
  end

  def test_show_fail_not_logged_in
    changeset = create(:changeset)

    get changeset_tags_path(changeset)
    assert_redirected_to login_path(:referer => changeset_tags_path(changeset))
  end

  def test_show_fail_not_moderator
    changeset = create(:changeset)
    user = create(:user)

    session_for(user)

    get changeset_tags_path(changeset)
    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  private

  def check_tag_table_row(row, _changeset, key, value)
    assert_dom row, "th", :text => key
    assert_dom row, "td", :text => value
  end
end
