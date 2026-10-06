# frozen_string_literal: true

require "test_helper"

module Notifications
  class ReadsControllerTest < ActionDispatch::IntegrationTest
    def test_routes
      assert_routing(
        { :path => "/notifications/reads", :method => :post },
        { :controller => "notifications/reads", :action => "create" }
      )
    end

    def test_create_unauthorized
      user1 = create(:user)
      user2 = create(:user)
      n1 = create(:changeset_comment_notification, :recipient => user1)
      n2 = create(:changeset_comment_notification, :recipient => user2)

      assert_difference(unread_counter, 0) do
        post notifications_reads_path, :params => { :notification_ids => [n1.id, n2.id] }
      end
      assert_response :forbidden
    end

    def test_create
      user1 = create(:user)
      user2 = create(:user)
      n1 = create(:changeset_comment_notification, :recipient => user1)
      n2 = create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, -1) do
        post notifications_reads_path, :params => { :notification_ids => [n1.id, n2.id] }
      end
      assert_redirected_to notifications_path
    end

    def test_create_missing_param
      user1 = create(:user)
      user2 = create(:user)
      create(:changeset_comment_notification, :recipient => user1)
      create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, 0) do
        post notifications_reads_path
      end
      assert_redirected_to notifications_path
    end

    private

    def unread_counter
      -> { Noticed::Notification.unread.count }
    end
  end
end
