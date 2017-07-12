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
    assert_template "user/login"
    # We can now login
    post "/login", :params => { "username" => user.email, "password" => "test", :referer => "/diary/new" }
    assert_response :redirect
    # print @response.body
    # Check that there is some payload alerting the user to the redirect
    # and allowing them to get to the page they are being directed to
    assert_select "html:root" do
      assert_select "body" do
        assert_select "a[href='http://www.example.com/diary/new']"
      end
    end
    # Required due to a bug in the rails testing framework
    # http://markmail.org/message/wnslvi5xv5moqg7g
    @html_document = nil
    follow_redirect!

    assert_response :success
    assert_template "diary_entry/edit"
    # print @response.body
    # print @html_document.to_yaml

    # We will make sure that the form exists here, full
    # assert testing of the full form should be done in the
    # functional tests rather than this integration test
    # There are some things that are specific to the integratio
    # that need to be tested, which can't be tested in the functional tests
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", "New Diary Entry"
    end
    assert_select "div#content" do
      assert_select "form[action='/diary/new']" do
        assert_select "input[id=diary_entry_title]"
      end
    end
  end
end
