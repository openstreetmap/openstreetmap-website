class Notifier < ActionMailer::Base
  def signup_confirm(user, token)
    common_headers user
    subject I18n.t('notifier.signup_confirm.subject')
    body :url => url_for(:host => SERVER_URL,
                         :controller => "user", :action => "confirm",
                         :display_name => user.display_name,
                         :confirm_string => token.token)
  end

  def email_confirm(user, token)
    common_headers user
    recipients user.new_email
    subject I18n.t('notifier.email_confirm.subject')
    body :address => user.new_email,
         :url => url_for(:host => SERVER_URL,
                         :controller => "user", :action => "confirm_email",
                         :confirm_string => token.token)
  end

  def lost_password(user, token)
    common_headers user
    subject I18n.t('notifier.lost_password.subject')
    body :url => url_for(:host => SERVER_URL,
                         :controller => "user", :action => "reset_password",
                         :token => token.token)
  end

  def gpx_success(trace, possible_points)
    common_headers trace.user
    subject I18n.t('notifier.gpx_notification.success.subject')
    body :trace_name => trace.name,
         :trace_points => trace.size,
         :trace_description => trace.description,
         :trace_tags => trace.tags,
         :possible_points => possible_points
  end

  def gpx_failure(trace, error)
    common_headers trace.user
    from "webmaster@openstreetmap.org"
    subject I18n.t('notifier.gpx_notification.failure.subject')
    body :trace_name => trace.name,
         :trace_description => trace.description,
         :trace_tags => trace.tags,
         :error => error
  end
  
  def message_notification(message)
    common_headers message.recipient
    from_header message.sender.display_name, "m", message.id, message.digest
    subject I18n.t('notifier.message_notification.subject_header', :subject => message.title, :locale => locale)
    body :to_user => message.recipient.display_name,
         :from_user => message.sender.display_name,
         :body => message.body,
         :title => message.title,
         :readurl => url_for(:host => SERVER_URL,
                             :controller => "message", :action => "read",
                             :message_id => message.id),
         :replyurl => url_for(:host => SERVER_URL,
                              :controller => "message", :action => "reply",
                              :message_id => message.id)
  end

  def diary_comment_notification(comment)
    common_headers comment.diary_entry.user
    from_header comment.user.display_name, "c", comment.id, comment.digest
    subject I18n.t('notifier.diary_comment_notification.subject', :user => comment.user.display_name, :locale => locale)
    body :to_user => comment.diary_entry.user.display_name,
         :from_user => comment.user.display_name,
         :body => comment.body,
         :title => comment.diary_entry.title,
         :readurl => url_for(:host => SERVER_URL,
                             :controller => "diary_entry",
                             :action => "view",
                             :display_name => comment.diary_entry.user.display_name,
                             :id => comment.diary_entry.id,
                             :anchor => "comment#{comment.id}"),
         :commenturl => url_for(:host => SERVER_URL,
                                :controller => "diary_entry",
                                :action => "view",
                                :display_name => comment.diary_entry.user.display_name,
                                :id => comment.diary_entry.id,
                                :anchor => "newcomment"),
         :replyurl => url_for(:host => SERVER_URL,
                              :controller => "message",
                              :action => "new",
                              :display_name => comment.user.display_name,
                              :title => "Re: #{comment.diary_entry.title}")
  end

  def friend_notification(friend)
    common_headers friend.befriendee
    subject I18n.t('notifier.friend_notification.subject', :user => friend.befriender.display_name, :locale => locale)
    body :friend => friend
  end

private

  def common_headers(recipient)
    recipients recipient.email
    locale recipient.preferred_language_from(I18n.available_locales)
    from EMAIL_FROM
    headers "return-path" => EMAIL_RETURN_PATH,
            "Auto-Submitted" => "auto-generated"
  end

  def from_header(name, type, id, digest)
    if domain = MESSAGES_DOMAIN
      from quote_address_if_necessary("#{name} <#{type}-#{id}-#{digest[0,6]}@#{domain}>", "utf-8")
    end
  end
end
