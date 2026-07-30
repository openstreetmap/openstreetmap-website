# frozen_string_literal: true

require "test_helper"

module Notifications
  class DiaryCommentViewTest < ActionView::TestCase
    def test_render
      diary_comment = build_stubbed(:diary_comment)
      notification = build_stubbed(:notification, :record => diary_comment)

      render(
        "notifications/diary_comment",
        :notification => notification,
        :record => diary_comment
      )

      assert_dom ".user-notification h2", "Diary comment"
      assert_dom ".user-notification time", "less than 1 minute ago"
      assert_dom ".user-notification blockquote", diary_comment.body
    end
  end
end
