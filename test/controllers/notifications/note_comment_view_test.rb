# frozen_string_literal: true

require "test_helper"

module Notifications
  class NoteCommentViewTest < ActionView::TestCase
    def test_render_commented
      note_comment = build_stubbed(
        :note_comment,
        :author => build_stubbed(:user),
        :event => "commented"
      )
      notification = build_stubbed(:notification, :record => note_comment)

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "Note comment"
        assert_dom "time", "less than 1 minute ago"
        assert_dom "blockquote", note_comment.body
      end
    end

    def test_render_closed_with_comment
      comment_author = build_stubbed(
        :user,
        :display_name => "Helpful Commenter"
      )
      note = build_stubbed(:note)
      note_comment = build_stubbed(
        :note_comment,
        :author => comment_author,
        :note => note,
        :event => "closed"
      )
      notification = build_stubbed(:notification, :record => note_comment)

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "Note resolved"
        assert_dom "time", "less than 1 minute ago"
        assert_dom "blockquote", note_comment.body
      end
    end

    def test_render_closed_without_comment
      comment_author = build_stubbed(
        :user,
        :display_name => "Helpful Commenter"
      )
      note = build_stubbed(:note)
      note_comment = build_stubbed(
        :note_comment,
        :author => comment_author,
        :note => note,
        :event => "closed",
        :body => ""
      )
      notification = build_stubbed(:notification, :record => note_comment)

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "Note resolved"
        assert_dom "time", "less than 1 minute ago"
        assert_not_dom "blockquote"
      end
    end

    def test_render_reopened
      comment_author = build_stubbed(
        :user,
        :display_name => "Helpful Commenter"
      )
      note = build_stubbed(:note)
      note_comment = build_stubbed(
        :note_comment,
        :author => comment_author,
        :note => note,
        :event => "reopened",
        :body => ""
      )
      notification = build_stubbed(:notification, :record => note_comment)

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "Note reopened"
        assert_dom "time", "less than 1 minute ago"
        assert_not_dom "blockquote"
      end
    end
  end
end
