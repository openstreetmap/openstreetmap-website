# frozen_string_literal: true

require "test_helper"

class ChangesetCommentMentionNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_enabled
    mentioned = create(:user, :display_name => "Mentioned")
    mentioned.notification_preferences.update("changeset_comment_mention" => ["email"])

    trigger_notification("@Mentioned please check")

    email = ActionMailer::Base.deliveries.first
    assert_equal [mentioned.email], email.to
  end

  def test_do_not_send_email_when_disabled
    mentioned = create(:user, :display_name => "Mentioned")
    mentioned.notification_preferences.update("changeset_comment_mention" => [])

    trigger_notification("@Mentioned please check")

    assert_empty ActionMailer::Base.deliveries
  end

  def test_notifies_mentioned_users
    mentioned = create(:user, :display_name => "Mentioned")
    comment = create(:changeset_comment, :body => "@Mentioned please check")

    event = ChangesetCommentMentionNotifier.with(:record => comment).deliver

    assert_equal [mentioned], event.notifications.map(&:recipient)
  end

  def test_no_notifications_without_mentions
    comment = create(:changeset_comment, :body => "No mentions here")

    event = ChangesetCommentMentionNotifier.with(:record => comment).deliver

    assert_empty event.notifications
  end

  private

  def trigger_notification(body)
    changeset_comment = create(:changeset_comment, :body => body)

    perform_enqueued_jobs do
      Nominatim.stub :describe_location, nil do
        ChangesetCommentMentionNotifier.with(:record => changeset_comment).deliver
      end
    end
  end
end
