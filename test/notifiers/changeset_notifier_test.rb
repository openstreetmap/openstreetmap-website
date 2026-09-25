# frozen_string_literal: true

require "test_helper"

class ChangesetCommentNotifierTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_send_email_when_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("changeset_comment" => ["email"])

    trigger_notification(candidate_recipient)

    email = ActionMailer::Base.deliveries.first
    assert_equal [candidate_recipient.email], email.to
  end

  def test_do_not_send_email_when_not_subscribed
    candidate_recipient = create(:user)
    candidate_recipient.notification_preferences.update("changeset_comment" => [])

    trigger_notification(candidate_recipient)

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def trigger_notification(changeset_author)
    changeset = create(:changeset, :user => changeset_author)
    create(:changeset_subscription, :changeset => changeset, :subscriber => changeset_author)

    comment_author = create(:user)
    changeset_comment = create(:changeset_comment, :author => comment_author, :changeset => changeset)

    perform_enqueued_jobs do
      Nominatim.stub :describe_location, nil do
        ChangesetCommentNotifier.with(:record => changeset_comment).deliver
      end
    end
  end
end
