# frozen_string_literal: true

require "test_helper"

module Notifications
  class DiaryCommentViewTest < ActionView::TestCase
    def test_render
      comment_user = build_stubbed(
        :user,
        :display_name => "Helpful Commenter"
      )
      diary_entry = build_stubbed(:diary_entry)
      diary_comment = build_stubbed(
        :diary_comment,
        :user => comment_user,
        :diary_entry => diary_entry
      )
      notification = Struct.new(:record).new(diary_comment)
      notification_wrapper = UserNotifications::DiaryCommentNotification.new(notification)

      render "notifications/diary_comment", :notification => notification_wrapper

      assert_dom ".user-notification h2", "Diary comment"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification blockquote", diary_comment.body
    end
  end
end
