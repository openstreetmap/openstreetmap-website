class Notifier < ActionMailer::Base
  default :from => EMAIL_FROM,
          :return_path => EMAIL_RETURN_PATH,
          :auto_submitted => "auto-generated"
  helper :application

  def signup_confirm(user, token)
    with_recipient_locale user do
      @url = url_for(:host => SERVER_URL,
                     :controller => "user", :action => "confirm",
                     :display_name => user.display_name,
                     :confirm_string => token.token)

      mail :to => user.email,
           :subject => I18n.t('notifier.signup_confirm.subject')
    end
  end

  def email_confirm(user, token)
    with_recipient_locale user do
      @address = user.new_email
      @url = url_for(:host => SERVER_URL,
                     :controller => "user", :action => "confirm_email",
                     :confirm_string => token.token)

      mail :to => user.new_email,
           :subject => I18n.t('notifier.email_confirm.subject')
    end
  end

  def lost_password(user, token)
    with_recipient_locale user do
      @url = url_for(:host => SERVER_URL,
                     :controller => "user", :action => "reset_password",
                     :token => token.token)

      mail :to => user.email,
           :subject => I18n.t('notifier.lost_password.subject')
    end
  end

  def gpx_success(trace, possible_points)
    with_recipient_locale trace.user do
      @trace_name = trace.name
      @trace_points = trace.size
      @trace_description = trace.description
      @trace_tags = trace.tags
      @possible_points = possible_points

      mail :to => trace.user.email,
           :subject => I18n.t('notifier.gpx_notification.success.subject')
    end
  end

  def gpx_failure(trace, error)
    with_recipient_locale trace.user do
      @trace_name = trace.name
      @trace_description = trace.description
      @trace_tags = trace.tags
      @error = error

      mail :to => trace.user.email,
           :subject => I18n.t('notifier.gpx_notification.failure.subject')
    end
  end

  def message_notification(message)
    with_recipient_locale message.recipient do
      @to_user = message.recipient.display_name
      @from_user = message.sender.display_name
      @text = message.body
      @title = message.title
      @readurl = url_for(:host => SERVER_URL,
                         :controller => "message", :action => "read",
                         :message_id => message.id)
      @replyurl = url_for(:host => SERVER_URL,
                          :controller => "message", :action => "reply",
                          :message_id => message.id)

      mail :from => from_address(message.sender.display_name, "m", message.id, message.digest),
           :to => message.recipient.email,
           :subject => I18n.t('notifier.message_notification.subject_header', :subject => message.title)
    end
  end

  def diary_comment_notification(comment)
    with_recipient_locale comment.diary_entry.user do
      @to_user = comment.diary_entry.user.display_name
      @from_user = comment.user.display_name
      @text = comment.body
      @title = comment.diary_entry.title
      @readurl = url_for(:host => SERVER_URL,
                         :controller => "diary_entry",
                         :action => "view",
                         :display_name => comment.diary_entry.user.display_name,
                         :id => comment.diary_entry.id,
                         :anchor => "comment#{comment.id}")
      @commenturl = url_for(:host => SERVER_URL,
                            :controller => "diary_entry",
                            :action => "view",
                            :display_name => comment.diary_entry.user.display_name,
                            :id => comment.diary_entry.id,
                            :anchor => "newcomment")
      @replyurl = url_for(:host => SERVER_URL,
                          :controller => "message",
                          :action => "new",
                          :display_name => comment.user.display_name,
                          :title => "Re: #{comment.diary_entry.title}")

      mail :from => from_address(comment.user.display_name, "c", comment.id, comment.digest),
           :to =>  comment.diary_entry.user.email,
           :subject => I18n.t('notifier.diary_comment_notification.subject', :user => comment.user.display_name)
    end
  end

  def friend_notification(friend)
    with_recipient_locale friend.befriendee do
      @friend = friend

      mail :to => friend.befriendee.email,
           :subject => I18n.t('notifier.friend_notification.subject', :user => friend.befriender.display_name)
    end
  end

  def note_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @noteurl = browse_note_url(comment.note, :host => SERVER_URL)
      @place = Nominatim.describe_location(comment.note.lat, comment.note.lon, 14, I18n.locale)
      @comment = comment.body
      @owner = recipient == comment.note.author
      @event = comment.event

      if comment.author
        @commenter = comment.author.display_name
      else
        @commenter = I18n.t("notifier.note_comment_notification.anonymous")
      end

      if @owner
        subject = I18n.t("notifier.note_comment_notification.#{@event}.subject_own", :commenter => @commenter)
      else
        subject = I18n.t("notifier.note_comment_notification.#{@event}.subject_other", :commenter => @commenter)
      end

      mail :to => recipient.email, :subject => subject
    end
  end

private

  def with_recipient_locale(recipient)
    old_locale = I18n.locale

    begin
      I18n.locale = recipient.preferred_language_from(I18n.available_locales)

      yield
    ensure
      I18n.locale = old_locale
    end
  end

  def from_address(name, type, id, digest)
    if Object.const_defined?(:MESSAGES_DOMAIN) and domain = MESSAGES_DOMAIN
      "#{name} <#{type}-#{id}-#{digest[0,6]}@#{domain}>"
    else
      EMAIL_FROM
    end
  end
end
