# frozen_string_literal: true

require "test_helper"

module Notifications
  class DiaryCommentViewTest < ActionView::TestCase
    def test_render
      diary_comment = build_stubbed(:diary_comment)
      notification = build_stubbed(:notification, :record => diary_comment)

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification" do
        assert_dom "h2", "Diary comment"
        assert_dom "time", "less than 1 minute ago"
        assert_dom "blockquote", diary_comment.body
      end
    end

    def test_render_with_long_text
      comment_user = build_stubbed(
        :user,
        :display_name => "Helpful Commenter"
      )
      diary_entry = build_stubbed(:diary_entry)
      diary_comment = build_stubbed(
        :diary_comment,
        :user => comment_user,
        :diary_entry => diary_entry,
        :body => read_fixture_file("lorem_ipsum.txt")
      )
      notification = build_stubbed(:notification, :record => diary_comment)

      render(
        "notifications/notification",
        :notification => notification
      )

      assert_dom ".web-notification blockquote p", :count => 3
    end
  end
end
