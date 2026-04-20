# frozen_string_literal: true

require "test_helper"

module Notifications
  class GpxImportFailureViewTest < ActionView::TestCase
    def test_render
      notification = build_stubbed(
        :notification,
        :notifier_class => GpxImportFailureNotifier,
        :notifier_params => {
          :trace_name => "random-file.jpg",
          :trace_description => "Random file",
          :trace_tags => %w[random file],
          :error => "Ooops, wrong file"
        }
      )

      notification_wrapper = UserNotifications::GpxImportFailureNotification.new(notification)

      render "notifications/gpx_import_failure", :notification => notification_wrapper

      assert_dom ".user-notification h2", "GPS trace could not be imported"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification dd", "random-file.jpg"
      assert_dom ".user-notification dd", "Random file"
      assert_dom ".user-notification dd", "random, file"
      assert_dom ".user-notification pre", "Ooops, wrong file"
    end
  end
end
