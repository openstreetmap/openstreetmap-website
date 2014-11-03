require 'test_helper'

class UserChangesetCommentsTest < ActionDispatch::IntegrationTest
  fixtures :users, :changesets, :changeset_comments

  # Test 'log in to comment' message for nonlogged in user
  def test_log_in_message
    get "/changeset/#{changesets(:normal_user_closed_change).id}"
    assert_response :success
    
    assert_select "div#content" do
      assert_select "div#sidebar" do
        assert_select "div#sidebar_content" do
          assert_select "div.browse-section" do
            assert_select "div.notice.hide_if_logged_in"
          end
        end
      end
    end
  end

  # Test if the form is shown
  def test_displaying_form
    get_via_redirect '/login'
    # We should now be at the login page
    assert_response :success
    assert_template 'user/login'
    # We can now login
    post  '/login', {'username' => "test@openstreetmap.org", 'password' => "test"}
    assert_response :redirect

    get "/changeset/#{changesets(:normal_user_closed_change).id}"
    
    assert_response :success
    assert_template 'browse/changeset'

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
