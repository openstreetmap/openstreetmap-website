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

  def diary_comment_notification
    recipient = create(:user, :languages => [I18n.locale])
    diary_entry = create(:diary_entry)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    UserMailer.diary_comment_notification(diary_comment, recipient)
  end
end
