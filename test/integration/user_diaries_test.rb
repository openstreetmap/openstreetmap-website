require "test_helper"

class UserDiariesTest < ActionDispatch::IntegrationTest
  # Test the creation of a diary entry, making sure that you are redirected to
  # login page when not logged in
  def test_showing_create_diary_entry
    user = create(:user)

    get "/diary/new"
    follow_redirect!
    follow_redirect!
    # We should now be at the login page
    assert_response :success
    assert_template "sessions/new"
    # We can now login
    post "/login", :params => { "username" => user.email, "password" => "test", :referer => "/diary/new" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template "diary_entries/new"

    # We will make sure that the form exists here, full
    # assert testing of the full form should be done in the
    # functional tests rather than this integration test
    # There are some things that are specific to the integratio
    # that need to be tested, which can't be tested in the functional tests
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", "New Diary Entry"
    end
    assert_select "div#content" do
      assert_select "form[action='/diary']" do
        assert_select "input[id=diary_entry_title]"
      end
    end
  end
end
