# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def test_signup_confirm
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    referer = "the-referer"
    email = UserMailer.with(
      :user => user,
      :token => token,
      :referer => referer
    ).signup_confirm

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
    email = UserMailer.with(:user => user, :token => token).email_confirm

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
    email = UserMailer.with(:user => user, :token => token).lost_password

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
    email = UserMailer.with(:record => trace, :possible_points => 100, :recipient => trace.user).gpx_success

    assert_match("one, two&amp;three, four&lt;five", email.html_part.body.to_s)
    assert_match("one, two&three, four<five", email.text_part.body.to_s)
  end

  def test_gpx_success_all_traces_link
    trace = create(:trace)
    email = UserMailer.with(:record => trace, :possible_points => 100, :recipient => trace.user).gpx_success
    url = url_helpers.url_for(:controller => "traces", :action => "mine")

    assert_select parse_html_body(email), "a[href='#{url}']"
    assert_includes email.text_part.body, url
  end

  def test_gpx_success_trace_link
    trace = create(:trace)
    email = UserMailer.with(:record => trace, :possible_points => 100, :recipient => trace.user).gpx_success
    url = url_helpers.show_trace_url(trace.user, trace)

    assert_select parse_html_body(email), "a[href='#{url}']", :text => trace.name
    assert_includes email.text_part.body, url
  end

  def test_gpx_failure
    trace = build(:trace, :tags => build_list(:tracetag, 2))
    email = UserMailer.with(
      :trace_name => trace.name,
      :trace_description => trace.description,
      :trace_tags => trace.tags,
      :error => "some error",
      :recipient => trace.user
    ).gpx_failure

    tags = trace.tags.map(&:tag)
    assert_match trace.name, email.html_part.body.to_s
    assert_match trace.description, email.html_part.body.to_s
    assert_match tags[0], email.html_part.body.to_s
    assert_match tags[1], email.html_part.body.to_s
    assert_match "some error", email.html_part.body.to_s

    tags = trace.tags.map(&:tag)
    assert_match trace.name, email.text_part.body.to_s
    assert_match trace.description, email.text_part.body.to_s
    assert_match tags[0], email.text_part.body.to_s
    assert_match tags[1], email.text_part.body.to_s
    assert_match "some error", email.text_part.body.to_s
  end

  def test_message_notification
    sender = create(:user, :display_name => "Jack & Jill <br>")
    recipient = create(:user)
    message = create(:message, :sender => sender, :recipient => recipient)
    email = UserMailer.with(:record => message, :recipient => recipient).message_notification

    assert_match("Jack & Jill <br>", email.text_part.body.to_s)
    assert_match("Jack &amp; Jill &lt;br&gt;", email.html_part.body.to_s)
    assert_match(/<html lang=/, email.html_part.body.to_s)
  end

  def test_diary_comment_notification
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    email = UserMailer.with(:record => diary_comment, :recipient => other_user).diary_comment_notification
    body = parse_html_body(email)

    url = url_helpers.diary_entry_url(user, diary_entry)
    unsubscribe_url = url_helpers.diary_entry_unsubscribe_url(user, diary_entry)
    assert_select body, "a[href^='#{url}']"
    assert_select body, "a[href='#{unsubscribe_url}']", :count => 1
  end

  def test_follow_notification
    follow = create(:follow)
    email = UserMailer.with(:record => follow, :recipient => follow.following).follow_notification

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
    email = UserMailer.with(:record => comment, :recipient => recipient).note_comment_notification
    html_body =
      Nominatim.stub :describe_location, "The End of the Rainbow" do
        parse_html_body(email)
      end

    url = url_helpers.note_url(note)
    assert_select html_body, "a[href^='#{url}']"
    assert_match url, email.text_part.body.to_s
  end

  def test_changeset_comment_notification
    user = create(:user)
    other_user = create(:user)
    changeset = create(:changeset, :user => user)
    changeset_comment = create(:changeset_comment, :changeset => changeset)
    email = UserMailer.with(:record => changeset_comment, :recipient => other_user).changeset_comment_notification
    body = parse_html_body(email)

    url = url_helpers.changeset_url(changeset)
    unsubscribe_url = url_helpers.changeset_subscription_url(changeset)
    assert_select body, "a[href^='#{url}']"
    assert_select body, "a[href='#{unsubscribe_url}']", :count => 1
  end

  private

  def parse_html_body(email)
    parse_html(email.html_part.body)
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
