# frozen_string_literal: true

require "test_helper"

class DiaryCommentNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("diary_comment" => ["email"])

    trigger_notification(candidate_recipient)

    email = ActionMailer::Base.deliveries.first
    assert_equal [candidate_recipient.email], email.to
  end

  def test_do_not_send_email_when_not_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("diary_comment" => [])

    trigger_notification(candidate_recipient)

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def trigger_notification(diary_author)
    create(:language, :code => "en")
    diary_entry = create(:diary_entry, :user => diary_author)
    create(:diary_entry_subscription, :diary_entry => diary_entry, :user => diary_author)

    comment_author = create(:user)
    diary_comment = create(:diary_comment, :user => comment_author, :diary_entry => diary_entry)

    perform_enqueued_jobs do
      DiaryCommentNotifier.with(:record => diary_comment).deliver
    end
  end
end
