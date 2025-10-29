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
    UserMailer.signup_confirm(user, token)
  end

  def email_confirm
    user = create(:user, :languages => [I18n.locale], :new_email => "newemail@example.com")
    token = "token-123456"
    UserMailer.email_confirm(user, token)
  end

  def lost_password
    user = create(:user, :languages => [I18n.locale])
    token = "token-123456"
    UserMailer.lost_password(user, token)
  end

  def gpx_success
    user = create(:user, :languages => [I18n.locale])
    trace = create(:trace, :user => user)
    UserMailer.gpx_success(trace, trace.size + 2)
  end

  def gpx_failure
    user = create(:user, :languages => [I18n.locale])
    trace = create(:trace, :user => user)
    error = begin
      LibXML::XML::Parser.string("<gpx>").parse
    rescue LibXML::XML::Error => e
      e.message
    end
    UserMailer.gpx_failure(trace, error)
  end

  def message_notification
    recipient = create(:user, :languages => [I18n.locale])
    message = create(:message, :recipient => recipient)
    UserMailer.message_notification(message)
  end

  def diary_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    diary_entry = create(:diary_entry)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    UserMailer.diary_comment_notification(diary_comment, recipient)
  end

  def follow_notification
    following = create(:user, :languages => [I18n.locale])
    follow = create(:follow, :following => following)
    UserMailer.follow_notification(follow)
  end

  def note_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    commenter = create(:user)
    comment = create(:note_comment, :author => commenter)
    UserMailer.note_comment_notification(comment, recipient)
  end

  def changeset_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    comment = create(:changeset_comment)
    UserMailer.changeset_comment_notification(comment, recipient)
  end
end
