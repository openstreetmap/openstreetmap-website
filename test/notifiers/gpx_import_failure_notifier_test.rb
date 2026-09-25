# frozen_string_literal: true

require "test_helper"

class GpxImportFailureNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("gpx_import_failure" => ["email"])

    trigger_notification(candidate_recipient)

    email = ActionMailer::Base.deliveries.first
    assert_equal [candidate_recipient.email], email.to
  end

  def test_do_not_send_email_when_not_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("gpx_import_failure" => [])

    trigger_notification(candidate_recipient)

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def trigger_notification(trace_author)
    perform_enqueued_jobs do
      GpxImportFailureNotifier.with(
        :trace_name => "My trace",
        :trace_description => "There are others like it, etc",
        :trace_tags => %w[vegetarian assume elapse],
        :error => "I'm sorry, Dave"
      ).deliver(trace_author)
    end
  end
end
