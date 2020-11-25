require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def test_html_layout_is_used
    email = UserMailer.message_notification(create(:message))

    assert_match(/<html lang=/, email.html_part.body.to_s)
  end

  def test_gpx_description_tags
    trace = create(:trace) do |t|
      create(:tracetag, :trace => t, :tag => "one")
      create(:tracetag, :trace => t, :tag => "two")
      create(:tracetag, :trace => t, :tag => "three")
    end
    email = UserMailer.gpx_success(trace, 100)

    assert_match(/one two three/, email.html_part.body.to_s)
  end
end
