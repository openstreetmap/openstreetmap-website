# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def test_signup_confirm
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    referer = "the-referer"
    email = UserMailer.signup_confirm(user, token, referer)

    confirmation_url = url_helpers.url_for(
      :controller => "confirmations",
      :action => "confirm",
      :display_name => user.display_name,
      :confirm_string => token,
      :referer => referer
    )
    assert_match(ERB::Util.html_escape_once(confirmation_url), email.html_part.body.to_s)
    assert_match(confirmation_url, email.text_part.body.to_s)
  end

  def test_email_confirm
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    email = UserMailer.email_confirm(user, token)

    confirmation_url = url_helpers.url_for(
      :controller => "confirmations",
      :action => "confirm_email",
      :confirm_string => token
    )
    assert_match(ERB::Util.html_escape_once(confirmation_url), email.html_part.body.to_s)
    assert_match(confirmation_url, email.text_part.body.to_s)
  end

  def test_lost_password
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    email = UserMailer.lost_password(user, token)

    recovery_url = url_helpers.user_reset_password_url(:token => token)
    assert_match(ERB::Util.html_escape_once(recovery_url), email.html_part.body.to_s)
    assert_match(recovery_url, email.text_part.body.to_s)
  end

  def test_gpx_success_description_tags
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
    url = url_helpers.url_for(:controller => "traces", :action => "mine")

    assert_select Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body),
                  "a[href='#{url}']"
    assert_includes email.text_part.body, url
  end

  def test_gpx_success_trace_link
    trace = create(:trace)
    email = UserMailer.gpx_success(trace, 100)
    url = url_helpers.show_trace_url(trace.user, trace)

    assert_select parse_html_body(email), "a[href='#{url}']", :text => trace.name
    assert_includes email.text_part.body, url
  end

  def test_gpx_failure_no_trace_link
    trace = create(:trace)
    email = UserMailer.gpx_failure(trace, "some error")
    url = url_helpers.show_trace_url(trace.user, trace)

    assert_select parse_html_body(email), "a[href='#{url}']", :count => 0
    assert_not_includes email.text_part.body, url
  end

  def test_message_notification
    user = create(:user, :display_name => "Jack & Jill <br>")
    message = create(:message, :sender => user)
    email = UserMailer.message_notification(message)

    assert_match("Jack & Jill <br>", email.text_part.body.to_s)
    assert_match("Jack &amp; Jill &lt;br&gt;", email.html_part.body.to_s)
    assert_match(/<html lang=/, email.html_part.body.to_s)
  end

  def test_diary_comment_notification
    create(:language, :code => "en")
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    email = UserMailer.diary_comment_notification(diary_comment, other_user)
    body = parse_html_body(email)

    url = url_helpers.diary_entry_url(user, diary_entry)
    unsubscribe_url = url_helpers.diary_entry_unsubscribe_url(user, diary_entry)
    assert_select body, "a[href^='#{url}']"
    assert_select body, "a[href='#{unsubscribe_url}']", :count => 1
  end

  def test_follow_notification
    follow = create(:follow)
    email = UserMailer.follow_notification(follow)

    follower_profile_url = url_helpers.user_url(follow.follower)
    follow_follower_url = url_helpers.follow_url(follow.follower)
    assert_match(ERB::Util.html_escape_once(follower_profile_url), email.html_part.body.to_s)
    assert_match(ERB::Util.html_escape_once(follow_follower_url), email.html_part.body.to_s)
    assert_match(follower_profile_url, email.text_part.body.to_s)
    assert_match(follow_follower_url, email.text_part.body.to_s)
  end

  def test_note_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    commenter = create(:user)
    note = create(:note, :lat => 51.7632, :lon => -0.0076)
    comment = create(:note_comment, :author => commenter, :note => note)
    email = UserMailer.note_comment_notification(comment, recipient)
    html_body =
      Nominatim.stub :describe_location, "The End of the Rainbow" do
        parse_html_body(email)
      end

    url = url_helpers.note_url(note)
    assert_select html_body, "a[href^='#{url}']"
    assert_match url, email.text_part.body.to_s
  end

  def test_changeset_comment_notification
    create(:language, :code => "en")
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    changeset_comment = create(:changeset_comment, :changeset => changeset)
    email = UserMailer.changeset_comment_notification(changeset_comment, other_user)
    body = parse_html_body(email)

    url = url_helpers.changeset_url(changeset)
    unsubscribe_url = url_helpers.changeset_subscription_url(changeset)
    assert_select body, "a[href^='#{url}']"
    assert_select body, "a[href='#{unsubscribe_url}']", :count => 1
  end

  private

  def parse_html_body(email)
    Rails::Dom::Testing.html_document_fragment.parse(email.html_part.body)
  end

  def url_helpers
    UrlHelpers.new
  end

  class UrlHelpers
    def method_missing(method, *args)
      opts = args.extract_options!
      opts.reverse_merge!(:host => Settings.server_url, :protocol => Settings.server_protocol)
      url_helpers.send(method, *args, opts)
    end

    def respond_to_missing?(method, include_all)
      url_helpers.respond_to?(method, include_all)
    end

    private

    def url_helpers
      Rails.application.routes.url_helpers
    end
  end
end
