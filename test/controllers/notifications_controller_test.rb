# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/notifications", :method => :get },
      { :controller => "notifications", :action => "index" }
    )
  end

  def test_index
    session_for(create(:user))
    get notifications_path

    assert_response :success
    assert_template "index"
  end

  def test_index_lists_changeset_comment_mentions
    user = create(:user)
    create(:notification, :recipient => user,
                          :record => create(:changeset_comment),
                          :notifier_class => ChangesetCommentMentionNotifier)
    session_for(user)
    get notifications_path

    assert_response :success
    assert_dom ".web-notification h2", "Mention in a changeset comment"
  end

  def test_index_unauthorized
    get notifications_path

    assert_redirected_to login_path(:referer => notifications_path)
  end
end
