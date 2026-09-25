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

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "GPS trace imported successfully"
        assert_dom "time", "less than 1 minute ago"
        assert_dom "dd", "test-trace-file.gpx"
        assert_dom "dd", "Test trace file"
        assert_dom "dd", "5"
      end
    end
  end
end
