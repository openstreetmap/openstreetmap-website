# frozen_string_literal: true

require "test_helper"

module Notifications
  class ReadsControllerTest < ActionDispatch::IntegrationTest
    test "routes" do
      assert_routing(
        { :path => "/notifications/reads", :method => :post },
        { :controller => "notifications/reads", :action => "create" }
      )
      assert_routing(
        { :path => "/notifications/reads", :method => :delete },
        { :controller => "notifications/reads", :action => "destroy" }
      )
    end

    test "create, unauthorized" do
      user = create(:user)
      notification = create(:changeset_comment_notification, :recipient => user)

      assert_difference(unread_counter, 0) do
        post notifications_reads_path, :params => { :notification_ids => [notification.id] }
      end
      assert_response :forbidden
    end

    test "create" do
      user1 = create(:user)
      user2 = create(:user)
      unread_notification = create(:changeset_comment_notification, :recipient => user1)
      read_notification = create(:changeset_comment_notification, :recipient => user1, :read_at => 1.minute.ago)
      _other_notification = create(:changeset_comment_notification, :recipient => user1)
      not_mine = create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, -1) do
        post(
          notifications_reads_path,
          :params => {
            :notification_ids => [
              unread_notification.id,
              read_notification.id,
              not_mine.id
            ]
          }
        )
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
        post notifications_reads_path
      end
      assert_redirected_to notifications_path
    end

    test "destroy, unauthorized" do
      user = create(:user)
      notification = create(:changeset_comment_notification, :recipient => user)

      assert_difference(unread_counter, 0) do
        delete notifications_reads_path, :params => { :notification_ids => [notification.id] }
      end
      assert_response :forbidden
    end

    test "destroy" do
      user1 = create(:user)
      user2 = create(:user)
      unread_notification = create(:changeset_comment_notification, :recipient => user1)
      read_notification = create(:changeset_comment_notification, :recipient => user1, :read_at => 1.minute.ago)
      _other_notification = create(:changeset_comment_notification, :recipient => user1)
      not_mine = create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, 1) do
        delete(
          notifications_reads_path,
          :params => {
            :notification_ids => [
              unread_notification.id,
              read_notification.id,
              not_mine.id
            ]
          }
        )
      end
      assert_redirected_to notifications_path
    end

    test "destroy, missing params" do
      user1 = create(:user)
      user2 = create(:user)
      create(:changeset_comment_notification, :recipient => user1)
      create(:changeset_comment_notification, :recipient => user2)

      session_for(user1)

      assert_difference(unread_counter, 0) do
        delete notifications_reads_path
      end
      assert_redirected_to notifications_path
    end

    private

    def unread_counter
      -> { Noticed::Notification.unread.count }
    end
  end
end
