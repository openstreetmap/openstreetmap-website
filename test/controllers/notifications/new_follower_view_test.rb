# frozen_string_literal: true

require "test_helper"

module Notifications
  class NewFollowerViewTest < ActionView::TestCase
    def test_render
      follower = build_stubbed(:user, :display_name => "Follower")
      follow = build_stubbed(:follow, :follower => follower)

      notification = build_stubbed(:notification, :record => follow, :notifier_class => NewFollowerNotifier)
      notification_wrapper = UserNotifications::NewFollowerNotification.new(notification)

      render "notifications/new_follower", :notification => notification_wrapper

      assert_dom ".user-notification h2", "New follower"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification p", "User Follower started following you. You can follow them back if you wish."
    end
  end
end
