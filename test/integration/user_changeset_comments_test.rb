require "test_helper"

class UserChangesetCommentsTest < ActionDispatch::IntegrationTest
  # Test if the form is shown
  def test_displaying_form
    user = create(:user)
    changeset = create(:changeset, :closed)

    get "/login"
    follow_redirect!
    # We should now be at the login page
    assert_response :success
    assert_template "sessions/new"
    # We can now login
    post "/login", :params => { "username" => user.email, "password" => "test" }
    assert_response :redirect

    get "/changeset/#{changeset.id}"

    assert_response :success
    assert_template "browse/changeset"

    assert_select "div#content" do
      assert_select "div#sidebar" do
        assert_select "div#sidebar_content" do
          assert_select "div" do
            assert_select "form[action='#']" do
              assert_select "textarea[name=text]"
            end
          end
        end
      end
    end
  end
end
