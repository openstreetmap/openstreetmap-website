# frozen_string_literal: true

require "test_helper"

module Notifications
  class ChangesetCommentViewTest < ActionView::TestCase
    def test_render_without_summary
      changeset_comment = build_stubbed(
        :changeset_comment,
        :body => "Insightful comment"
      )
      notification = build_stubbed(:notification, :record => changeset_comment)
      notification_wrapper = UserNotifications::ChangesetCommentNotification.new(notification)

      render "notifications/changeset_comment", :notification => notification_wrapper

      assert_dom ".user-notification" do
        assert_dom "h2", "Changeset comment"
        assert_not_dom "p", /\("/
        assert_dom "time", "less than 1 minute ago"
        assert_dom "blockquote", "Insightful comment"
      end
    end

    def test_render_with_summary
      summary_tag = build_stubbed(
        :changeset_tag,
        :k => "comment",
        :v => "This is a summary"
      )
      changeset = build_stubbed(:changeset, :changeset_tags => [summary_tag])
      changeset_comment = build_stubbed(
        :changeset_comment,
        :changeset => changeset,
        :body => "Insightful comment"
      )
      notification = build_stubbed(:notification, :record => changeset_comment)
      notification_wrapper = UserNotifications::ChangesetCommentNotification.new(notification)

      render "notifications/changeset_comment", :notification => notification_wrapper

      assert_dom ".user-notification" do
        assert_dom "h2", "Changeset comment"
        assert_dom "time", "less than 1 minute ago"
        assert_dom ".event-description", /\("This is a summary"\)/
        assert_dom "blockquote", "Insightful comment"
      end
    end
  end
end
