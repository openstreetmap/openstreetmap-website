require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def test_html_layout_is_used
    email = UserMailer.message_notification(create(:message))

    assert_match(/<html lang=/, email.html_part.body.to_s)
  end

  def test_gpx_description_tags
    trace = create(:trace) do |t|
      create(:tracetag, :trace => t, :tag => "one")
      create(:tracetag, :trace => t, :tag => "two&three")
      create(:tracetag, :trace => t, :tag => "four<five")
    end
    email = UserMailer.gpx_success(trace, 100)

    assert_match("one, two&amp;three, four&lt;five", email.html_part.body.to_s)
    assert_match("one, two&three, four<five", email.text_part.body.to_s)
  end

  def test_gpx_success_all_traces_link
    trace = create(:trace)
    email = UserMailer.gpx_success(trace, 100)
    url = Rails.application.routes.url_helpers.url_for(:controller => "traces", :action => "mine", :host => Settings.server_url, :protocol => Settings.server_protocol)

    assert_select Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body),
                  "a[href='#{url}']"
    assert_includes email.text_part.body, url
  end

  def test_gpx_success_trace_link
    trace = create(:trace)
    email = UserMailer.gpx_success(trace, 100)
    url = Rails.application.routes.url_helpers.show_trace_url(trace.user, trace, :host => Settings.server_url, :protocol => Settings.server_protocol)

    assert_select Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body),
                  "a[href='#{url}']", :text => trace.name
    assert_includes email.text_part.body, url
  end

  def test_gpx_failure_no_trace_link
    trace = create(:trace)
    email = UserMailer.gpx_failure(trace, "some error")
    url = Rails.application.routes.url_helpers.show_trace_url(trace.user, trace, :host => Settings.server_url, :protocol => Settings.server_protocol)

    assert_select Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body),
                  "a[href='#{url}']", :count => 0
    assert_not_includes email.text_part.body, url
  end

  def test_html_encoding
    user = create(:user, :display_name => "Jack & Jill <br>")
    message = create(:message, :sender => user)
    email = UserMailer.message_notification(message)

    assert_match("Jack & Jill <br>", email.text_part.body.to_s)
    assert_match("Jack &amp; Jill &lt;br&gt;", email.html_part.body.to_s)
  end

  def test_diary_comment_notification
    create(:language, :code => "en")
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    email = UserMailer.diary_comment_notification(diary_comment, other_user)
    body = Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body)

    url = Rails.application.routes.url_helpers.diary_entry_url(user, diary_entry, :host => Settings.server_url, :protocol => Settings.server_protocol)
    unsubscribe_url = Rails.application.routes.url_helpers.diary_entry_unsubscribe_url(user, diary_entry, :host => Settings.server_url, :protocol => Settings.server_protocol)
    assert_select body, "a[href^='#{url}']"
    assert_select body, "a[href='#{unsubscribe_url}']", :count => 1
  end

  def test_changeset_comment_notification
    create(:language, :code => "en")
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    changeset_comment = create(:changeset_comment, :changeset => changeset)
    email = UserMailer.changeset_comment_notification(changeset_comment, other_user)
    body = Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body)

    url = Rails.application.routes.url_helpers.changeset_url(changeset, :host => Settings.server_url, :protocol => Settings.server_protocol)
    unsubscribe_url = Rails.application.routes.url_helpers.changeset_subscription_url(changeset, :host => Settings.server_url, :protocol => Settings.server_protocol)
    assert_select body, "a[href^='#{url}']"
    assert_select body, "a[href='#{unsubscribe_url}']", :count => 1
  end
end
