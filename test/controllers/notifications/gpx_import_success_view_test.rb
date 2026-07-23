# frozen_string_literal: true

require "test_helper"

module Notifications
  class GpxImportSuccessViewTest < ActionView::TestCase
    def test_render
      trace = build_stubbed(
        :trace,
        :name => "test-trace-file.gpx",
        :description => "Test trace file"
      )
      notification = build_stubbed(
        :notification,
        :record => trace,
        :notifier_class => GpxImportSuccessNotifier,
        :notifier_params => {
          :possible_points => 5
        }
      )

      notification_wrapper = UserNotifications::GpxImportSuccessNotification.new(notification)

      render "notifications/gpx_import_success", :notification => notification_wrapper

      assert_dom ".user-notification h2", "GPS trace imported successfully"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification dd", "test-trace-file.gpx"
      assert_dom ".user-notification dd", "Test trace file"
      assert_dom ".user-notification dd", "5"
    end
  end
end
