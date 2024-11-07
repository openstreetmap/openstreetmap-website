require "test_helper"

class ChangesetTagsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/changeset/1/tags", :method => :get },
      { :controller => "changeset_tags", :action => "index", :changeset_id => "1" }
    )
  end

  def test_index_success
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

  def test_index_fail_no_changeset
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(999111)
    assert_response :not_found
  end

  def test_index_fail_not_logged_in
    changeset = create(:changeset)

    get changeset_tags_path(changeset)
    assert_redirected_to login_path(:referer => changeset_tags_path(changeset))
  end

  def test_index_fail_not_moderator
    changeset = create(:changeset)
    user = create(:user)

    session_for(user)

    get changeset_tags_path(changeset)
    assert_redirected_to :controller => :errors, :action => :forbidden
  end
end
