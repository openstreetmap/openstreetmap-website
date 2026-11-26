# frozen_string_literal: true

require "test_helper"

module Notifications
  class ChangesetCommentMentionViewTest < ActionView::TestCase
    def test_render_without_summary
      commenter = build_stubbed(:user, :display_name => "Helpful Commenter")
      changeset_comment = build_stubbed(
        :changeset_comment,
        :author => commenter,
        :body => "Please check this junction"
      )
      notification = build_stubbed(
        :notification,
        :record => changeset_comment,
        :notifier_class => ChangesetCommentMentionNotifier
      )

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "Mention in a changeset comment"
        assert_dom "h2 a[href='#{changeset_path(changeset_comment.changeset, :anchor => "c#{changeset_comment.id}")}']"
        assert_dom ".event-description", /Helpful Commenter mentioned you in a comment on changeset/
        assert_not_dom "p", /\("/
        assert_dom "blockquote", "Please check this junction"
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
        :body => "Please check this junction"
      )
      notification = build_stubbed(
        :notification,
        :record => changeset_comment,
        :notifier_class => ChangesetCommentMentionNotifier
      )

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification .event-description", /\("This is a summary"\)/
    end
  end
end
