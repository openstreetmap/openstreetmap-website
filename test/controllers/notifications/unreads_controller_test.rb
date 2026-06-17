# frozen_string_literal: true

require "test_helper"

module Notifications
  class UnreadsControllerTest < ActionDispatch::IntegrationTest
    test "routes" do
      assert_routing(
        { :path => "/notifications/unreads", :method => :post },
        { :controller => "notifications/unreads", :action => "create" }
      )
    end

    test "create, unauthorized" do
      user1 = create(:user)
      user2 = create(:user)
      n1 = create(:changeset_comment_notification, :recipient => user1)
      n2 = create(:changeset_comment_notification, :recipient => user2)

      assert_difference(unread_counter, 0) do
        post notifications_unreads_path, :params => { :notification_ids => [n1.id, n2.id] }
      end
      assert_response :forbidden
    end

    test "create" do
      user1 = create(:user)
      user2 = create(:user)
      _n1a = create(:changeset_comment_notification, :recipient => user1)
      n1b = create(:changeset_comment_notification, :recipient => user1, :read_at => 1.minute.ago)
      n1c = create(:changeset_comment_notification, :recipient => user1)
      n2 = create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, 1) do
        post notifications_unreads_path, :params => { :notification_ids => [n1b.id, n1c.id, n2.id] }
      end
      assert_redirected_to notifications_path
    end

    test "create, missing params" do
      user1 = create(:user)
      user2 = create(:user)
      create(:changeset_comment_notification, :recipient => user1)
      create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, 0) do
        post notifications_unreads_path
      end
      assert_redirected_to notifications_path
    end

    private

    def unread_counter
      -> { Noticed::Notification.unread.count }
    end
  end
end
