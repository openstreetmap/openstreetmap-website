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

  def test_gpx_success_trace_link
    trace = create(:trace)
    email = UserMailer.gpx_success(trace, 100)
    body = Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body)

    url = Rails.application.routes.url_helpers.show_trace_url(trace.user, trace, :host => Settings.server_url, :protocol => Settings.server_protocol)
    assert_select body, "a[href='#{url}']", :text => trace.name
  end

  def test_gpx_failure_no_trace_link
    trace = create(:trace)
    email = UserMailer.gpx_failure(trace, "some error")
    body = Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body)

    url = Rails.application.routes.url_helpers.show_trace_url(trace.user, trace, :host => Settings.server_url, :protocol => Settings.server_protocol)
    assert_select body, "a[href='#{url}']", :count => 0
  end

  def test_html_encoding
    user = create(:user, :display_name => "Jack & Jill <br>")
    message = create(:message, :sender => user)
    email = UserMailer.message_notification(message)

    assert_match("Jack & Jill <br>", email.text_part.body.to_s)
    assert_match("Jack &amp; Jill &lt;br&gt;", email.html_part.body.to_s)
  end
end
