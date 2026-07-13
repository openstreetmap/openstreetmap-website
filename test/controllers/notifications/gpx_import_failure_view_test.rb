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

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "GPS trace could not be imported"
        assert_dom "time", "less than 1 minute ago"
        assert_dom "dd", "random-file.jpg"
        assert_dom "dd", "Random file"
        assert_dom "dd", "random, file"
        assert_dom "pre", "Ooops, wrong file"
      end
    end
  end
end
