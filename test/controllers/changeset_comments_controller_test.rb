require "test_helper"

class ChangesetCommentsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/name/history/comments", :method => :get },
      { :controller => "changeset_comments", :action => "index", :display_name => "name" }
    )
  end

  ##
  # test comments webpage
  def test_index
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :closed)
    create_list(:changeset_comment, 3, :changeset => changeset, :author => user)
    create_list(:changeset_comment, 2, :changeset => changeset, :author => other_user)

    get changeset_comments_path(user)
    assert_response :success
    assert_select "table.table-striped tbody" do
      assert_select "tr", :count => 3
    end

    create(:changeset_comment, :changeset => changeset, :author => user)
    create(:changeset_comment, :changeset => changeset, :author => user, :visible => false)

    get changeset_comments_path(user)
    assert_response :success
    assert_select "table.table-striped tbody" do
      assert_select "tr", :count => 4
    end
  end
end
