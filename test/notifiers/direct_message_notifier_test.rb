# frozen_string_literal: true

require "test_helper"

class DirectMessageNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("direct_message" => ["email"])

    trigger_notification(candidate_recipient)

    email = ActionMailer::Base.deliveries.first
    assert_equal [candidate_recipient.email], email.to
  end

  def test_do_not_send_email_when_not_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("direct_message" => [])

    trigger_notification(candidate_recipient)

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def trigger_notification(message_recipient)
    message = create(:message, :recipient => message_recipient)

    perform_enqueued_jobs do
      DirectMessageNotifier.with(:record => message).deliver
    end
  end
end
