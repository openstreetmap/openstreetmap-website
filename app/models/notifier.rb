class Notifier < ActionMailer::Base
  default :from => EMAIL_FROM,
          :return_path => EMAIL_RETURN_PATH,
          :auto_submitted => "auto-generated"
  helper :application

  def signup_confirm(user, token)
    @locale = user.preferred_language_from(I18n.available_locales)

    # If we are passed an email address verification token, create
    # the confirumation URL for account activation.
    #
    # Otherwise the email has already been verified e.g. through
    # a trusted openID provider and the account is active and a
    # confirmation URL is not needed.
    if token
      @url = url_for(:host => SERVER_URL,
                     :controller => "user", :action => "confirm",
                     :display_name => user.display_name,
                     :confirm_string => token.token)
    end

    mail :to => user.email,
         :subject => I18n.t('notifier.signup_confirm.subject', :locale => @locale)
  end

  def email_confirm(user, token)
    @locale = user.preferred_language_from(I18n.available_locales)
    @address = user.new_email
    @url = url_for(:host => SERVER_URL,
                   :controller => "user", :action => "confirm_email",
                   :confirm_string => token.token)

    mail :to => user.new_email,
         :subject => I18n.t('notifier.email_confirm.subject', :locale => @locale)
  end

  def lost_password(user, token)
    @locale = user.preferred_language_from(I18n.available_locales)
    @url = url_for(:host => SERVER_URL,
                   :controller => "user", :action => "reset_password",
                   :token => token.token)

    mail :to => user.email,
         :subject => I18n.t('notifier.lost_password.subject', :locale => @locale)
  end

  def gpx_success(trace, possible_points)
    @locale = trace.user.preferred_language_from(I18n.available_locales)
    @trace_name = trace.name
    @trace_points = trace.size
    @trace_description = trace.description
    @trace_tags = trace.tags
    @possible_points = possible_points

    mail :to => trace.user.email,
         :subject => I18n.t('notifier.gpx_notification.success.subject', :locale => @locale)
  end

  def gpx_failure(trace, error)
    @locale = trace.user.preferred_language_from(I18n.available_locales)
    @trace_name = trace.name
    @trace_description = trace.description
    @trace_tags = trace.tags
    @error = error

    mail :to => trace.user.email,
         :subject => I18n.t('notifier.gpx_notification.failure.subject', :locale => @locale)
  end

  def message_notification(message)
    @locale = message.recipient.preferred_language_from(I18n.available_locales)
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
         :subject => I18n.t('notifier.message_notification.subject_header', :subject => message.title, :locale => @locale)
  end

  def diary_comment_notification(comment)
    @locale = comment.diary_entry.user.preferred_language_from(I18n.available_locales)
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
         :subject => I18n.t('notifier.diary_comment_notification.subject', :user => comment.user.display_name, :locale => @locale)
  end

  def friend_notification(friend)
    @locale = friend.befriendee.preferred_language_from(I18n.available_locales)
    @friend = friend

    mail :to => friend.befriendee.email,
         :subject => I18n.t('notifier.friend_notification.subject', :user => friend.befriender.display_name, :locale => @locale)
  end

  def note_comment_notification(comment, recipient)
    @locale = recipient.preferred_language_from(I18n.available_locales)
    @noteurl = browse_note_url(comment.note, :host => SERVER_URL)
    @place = Nominatim.describe_location(comment.note.lat, comment.note.lon, 14, @locale)
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

private

  def from_address(name, type, id, digest)
    if Object.const_defined?(:MESSAGES_DOMAIN) and domain = MESSAGES_DOMAIN
      "#{name} <#{type}-#{id}-#{digest[0,6]}@#{domain}>"
    else
      EMAIL_FROM
    end
  end
end
