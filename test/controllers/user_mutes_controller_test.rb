require "test_helper"

class UserMutesControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/user/username/mute", :method => :post },
      { :controller => "user_mutes", :action => "create", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/mute", :method => :delete },
      { :controller => "user_mutes", :action => "destroy", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user_mutes", :method => :get },
      { :controller => "user_mutes", :action => "index" }
    )
  end

  def test_index
    user = create(:user)
    muted_user = create(:user)
    user.mutes.create(:subject => muted_user)
    session_for(user)

    get user_mutes_path
    assert_match "You have muted 1 User", @response.body
    assert_dom "tr a[href='#{user_path muted_user}']", :text => muted_user.display_name
  end

  def test_create
    user = create(:user)
    session_for(user)

    assert_equal 0, user.muted_users.count
    subject = create(:user, :display_name => "Bob")
    post user_mute_path(subject)
    assert_match "You muted Bob", flash[:notice]

    assert_equal 1, user.muted_users.count
    assert_equal subject, user.muted_users.first

    post user_mute_path(subject)
    assert_match "Bob could not be muted. Is already muted", flash[:error]
    assert_equal 1, user.muted_users.count
  end

  def test_destroy
    user = create(:user)
    session_for(user)

    subject = create(:user, :display_name => "Bob")
    user.mutes.create(:subject => subject)
    assert_equal 1, user.muted_users.count

    delete user_mute_path(subject)
    assert_match "You unmuted Bob", flash[:notice]
    assert_equal 0, user.muted_users.count

    delete user_mute_path(subject)
    assert_response :not_found
  end
end
