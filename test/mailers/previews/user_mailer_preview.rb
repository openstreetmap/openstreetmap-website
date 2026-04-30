# frozen_string_literal: true

require "factory_bot_rails"

class UserMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  # Wraps the preview in a transaction, so that no changes
  # are persisted to the development db
  def self.call(...)
    preview = nil
    ActiveRecord::Base.transaction do
      preview = super(...)
      raise ActiveRecord::Rollback
    end
    preview
  end

  def signup_confirm
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    referer = "the-referer"

    UserMailer.with(:user => user, :token => token, :referer => referer).signup_confirm
  end

  def email_confirm
    user = create(:user, :languages => [I18n.locale], :new_email => "newemail@example.com")
    token = "token-123456"
    UserMailer.with(:user => user, :token => token).email_confirm
  end

  def lost_password
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    UserMailer.with(:user => user, :token => token).lost_password
  end

  def gpx_success
    user = create(:user, :languages => [I18n.locale])
    trace = create(:trace, :user => user)
    UserMailer.with(:record => trace, :possible_points => trace.size + 2, :recipient => trace.user).gpx_success
  end

  def gpx_failure
    user = create(:user, :languages => [I18n.locale])
    trace = create(:trace, :user => user)
    error = begin
      LibXML::XML::Parser.string("<gpx>").parse
    rescue LibXML::XML::Error => e
      e.message
    end
    UserMailer.with(
      :trace_name => trace.name,
      :trace_description => trace.description,
      :trace_tags => trace.tags,
      :error => error,
      :recipient => trace.user
    ).gpx_failure
  end

  def message_notification
    recipient = create(:user, :languages => [I18n.locale])
    message = create(:message, :recipient => recipient)
    UserMailer.with(:record => message, :recipient => recipient).message_notification
  end

  def diary_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    diary_entry = create(:diary_entry)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    UserMailer.with(:record => diary_comment, :recipient => recipient).diary_comment_notification
  end

  def follow_notification
    following = create(:user, :languages => [I18n.locale])
    follow = create(:follow, :following => following)
    UserMailer.with(:record => follow, :recipient => following).follow_notification
  end

  def note_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    commenter = create(:user)
    comment = create(:note_comment, :author => commenter)
    UserMailer.with(:record => comment, :recipient => recipient).note_comment_notification
  end

  def changeset_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    comment = create(:changeset_comment)
    UserMailer.with(:record => comment, :recipient => recipient).changeset_comment_notification
  end
end
