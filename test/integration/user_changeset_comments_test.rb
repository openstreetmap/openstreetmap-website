require "test_helper"

class UserChangesetCommentsTest < ActionDispatch::IntegrationTest
  # Test 'log in to comment' message for nonlogged in user
  def test_log_in_message
    changeset = create(:changeset, :closed)

    get "/changeset/#{changeset.id}"
    assert_response :success

    assert_select "div#content" do
      assert_select "div#sidebar" do
        assert_select "div#sidebar_content" do
          assert_select "div.browse-section" do
            assert_select "div.notice" do
              assert_select "a[href='/login?referer=%2Fchangeset%2F#{changeset.id}']", :text => I18n.t("browse.changeset.join_discussion"), :count => 1
            end
          end
        end
      end
    end
  end

  # Test if the form is shown
  def test_displaying_form
    user = create(:user)
    changeset = create(:changeset, :closed)

    get "/login"
    follow_redirect!
    # We should now be at the login page
    assert_response :success
    assert_template "users/login"
    # We can now login
    post "/login", :params => { "username" => user.email, "password" => "test" }
    assert_response :redirect

    get "/changeset/#{changeset.id}"

    assert_response :success
    assert_template "browse/changeset"

    assert_select "div#content" do
      assert_select "div#sidebar" do
        assert_select "div#sidebar_content" do
          assert_select "div.browse-section" do
            assert_select "form[action='#']" do
              assert_select "textarea[name=text]"
            end
          end
        end
      end
    end
  end
end
