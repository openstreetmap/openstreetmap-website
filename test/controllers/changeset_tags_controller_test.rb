require "test_helper"

class ChangesetTagsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/changeset/1/tags", :method => :get },
      { :controller => "changeset_tags", :action => "index", :changeset_id => "1" }
    )
    assert_routing(
      { :path => "/changeset/1/tags/key", :method => :delete },
      { :controller => "changeset_tags", :action => "destroy", :changeset_id => "1", :key => "key" }
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

  def test_index_success_1_tag
    changeset = create(:changeset)
    create(:changeset_tag, :changeset => changeset, :k => "tested-tag-key", :v => "tested-tag-value")
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(changeset)
    assert_response :success

    assert_dom ".content-body" do
      assert_dom "tbody tr", :count => 1 do
        assert_dom "th", :text => "tested-tag-key"
        assert_dom "td", :text => "tested-tag-value"
        assert_dom "td form[action='#{changeset_tag_path(changeset, 'tested-tag-key')}']" do
          assert_dom "button", :text => "Delete"
        end
      end
    end
  end

  def test_index_success_2_tags
    changeset = create(:changeset)
    create(:changeset_tag, :changeset => changeset, :k => "tested-1st-tag-key", :v => "tested-1st-tag-value")
    create(:changeset_tag, :changeset => changeset, :k => "tested-2nd-tag-key", :v => "tested-2nd-tag-value")
    moderator_user = create(:moderator_user)

    session_for(moderator_user)

    get changeset_tags_path(changeset)
    assert_response :success

    assert_dom ".content-body" do
      assert_dom "tbody tr", :count => 2 do |rows|
        assert_dom rows[0], "th", :text => "tested-1st-tag-key"
        assert_dom rows[0], "td", :text => "tested-1st-tag-value"
        assert_dom rows[0], "td form[action='#{changeset_tag_path(changeset, 'tested-1st-tag-key')}']" do
          assert_dom "button", :text => "Delete"
        end
        assert_dom rows[1], "th", :text => "tested-2nd-tag-key"
        assert_dom rows[1], "td", :text => "tested-2nd-tag-value"
        assert_dom rows[1], "td form[action='#{changeset_tag_path(changeset, 'tested-2nd-tag-key')}']" do
          assert_dom "button", :text => "Delete"
        end
      end
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
