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
      notification_wrapper = UserNotifications::NoteCommentNotification.new(notification)

      render "notifications/note_comment", :notification => notification_wrapper

      assert_dom ".user-notification h2", "Note comment"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification blockquote", note_comment.body
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
      notification_wrapper = UserNotifications::NoteCommentNotification.new(notification)

      render "notifications/note_comment", :notification => notification_wrapper

      assert_dom ".user-notification h2", "Note resolved"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification blockquote", note_comment.body
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
      notification = Struct.new(:record).new(note_comment)
      notification_wrapper = UserNotifications::NoteCommentNotification.new(notification)

      render "notifications/note_comment", :notification => notification_wrapper

      assert_dom ".user-notification h2", "Note resolved"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_not_dom ".user-notification blockquote"
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
      notification = Struct.new(:record).new(note_comment)
      notification_wrapper = UserNotifications::NoteCommentNotification.new(notification)

      render "notifications/note_comment", :notification => notification_wrapper

      assert_dom ".user-notification h2", "Note reopened"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_not_dom ".user-notification blockquote"
    end
  end
end
