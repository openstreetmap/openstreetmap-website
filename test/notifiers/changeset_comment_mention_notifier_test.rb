# frozen_string_literal: true

require "test_helper"

class ChangesetCommentMentionNotifierTest < ActiveSupport::TestCase
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
end
