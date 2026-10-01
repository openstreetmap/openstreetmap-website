# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/notifications", :method => :get },
      { :controller => "notifications", :action => "index" }
    )
    assert_routing(
      { :path => "/notifications", :method => :delete },
      { :controller => "notifications", :action => "destroy" }
    )
  end

  def test_index
    session_for(create(:user))
    get notifications_path

    assert_response :success
    assert_template "index"
  end

  def test_index_unauthorized
    get notifications_path

    assert_redirected_to login_path(:referer => notifications_path)
  end

  def test_destroy_unauthorized
    user1 = create(:user)
    user2 = create(:user)
    n1 = create(:changeset_comment_notification, :recipient => user1)
    n2 = create(:changeset_comment_notification, :recipient => user2)

    assert_difference -> { Noticed::Notification.count } => 0 do
      delete notifications_path, :params => { :notifications => { n1.id => "delete", n2.id => "delete" } }
    end
    assert_response :forbidden
  end

  def test_destroy
    user1 = create(:user)
    user2 = create(:user)
    n1 = create(:changeset_comment_notification, :recipient => user1)
    n2 = create(:changeset_comment_notification, :recipient => user2)

    session_for(user1)

    assert_difference -> { Noticed::Notification.count } => -1 do
      delete notifications_path, :params => { :notifications => { n1.id => "delete", n2.id => "delete" } }
    end
    assert_redirected_to notifications_path
  end
end
