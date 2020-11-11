require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def test_html_layout_is_used
    email = UserMailer.message_notification(create(:message))

    assert_match(/<html lang=/, email.html_part.body.to_s)
  end
end
