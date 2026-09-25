# frozen_string_literal: true

require "test_helper"

class NoteCommentNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("note_comment" => ["email"])

    trigger_notification(candidate_recipient)

    email = ActionMailer::Base.deliveries.first
    assert_equal [candidate_recipient.email], email.to
  end

  def test_do_not_send_email_when_not_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("note_comment" => [])

    trigger_notification(candidate_recipient)

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def trigger_notification(note_author)
    note = create(:note, :author => note_author)
    create(:note_subscription, :note => note, :user => note_author)

    comment_author = create(:user)
    note_comment = create(:note_comment, :author => comment_author, :note => note)

    perform_enqueued_jobs do
      Nominatim.stub :describe_location, nil do
        NoteCommentNotifier.with(:record => note_comment).deliver
      end
    end
  end
end
