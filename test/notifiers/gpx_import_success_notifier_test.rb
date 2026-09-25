# frozen_string_literal: true

require "test_helper"

class GpxImportSuccessNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("gpx_import_success" => ["email"])

    trigger_notification(candidate_recipient)

    email = ActionMailer::Base.deliveries.first
    assert_equal [candidate_recipient.email], email.to
  end

  def test_do_not_send_email_when_not_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("gpx_import_success" => [])

    trigger_notification(candidate_recipient)

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def trigger_notification(trace_author)
    trace = create(:trace, :user => trace_author)

    perform_enqueued_jobs do
      GpxImportSuccessNotifier.with(:record => trace, :possible_points => 5).deliver
    end
  end
end
