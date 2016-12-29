require "base64"

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
           :subject => I18n.t("notifier.signup_confirm.subject")
    end
  end

  def email_confirm(user, token)
    with_recipient_locale user do
      @address = user.new_email
      @url = url_for(:host => SERVER_URL,
                     :controller => "user", :action => "confirm_email",
                     :confirm_string => token.token)

      mail :to => user.new_email,
           :subject => I18n.t("notifier.email_confirm.subject")
    end
  end

  def lost_password(user, token)
    with_recipient_locale user do
      @url = url_for(:host => SERVER_URL,
                     :controller => "user", :action => "reset_password",
                     :token => token.token)

      mail :to => user.email,
           :subject => I18n.t("notifier.lost_password.subject")
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
           :subject => I18n.t("notifier.gpx_notification.success.subject")
    end
  end

  def gpx_failure(trace, error)
    with_recipient_locale trace.user do
      @trace_name = trace.name
      @trace_description = trace.description
      @trace_tags = trace.tags
      @error = error

      mail :to => trace.user.email,
           :subject => I18n.t("notifier.gpx_notification.failure.subject")
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
           :subject => I18n.t("notifier.message_notification.subject_header", :subject => message.title)
    end
  end

  def diary_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @to_user = recipient.display_name
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

      mail :from => from_address(comment.user.display_name, "c", comment.id, comment.digest, recipient.id),
           :to => recipient.email,
           :subject => I18n.t("notifier.diary_comment_notification.subject", :user => comment.user.display_name)
    end
  end

  def friend_notification(friend)
    with_recipient_locale friend.befriendee do
      @friend = friend
      @viewurl = url_for(:host => SERVER_URL,
                         :controller => "user", :action => "view",
                         :display_name => @friend.befriender.display_name)
      @friendurl = url_for(:host => SERVER_URL,
                           :controller => "user", :action => "make_friend",
                           :display_name => @friend.befriender.display_name)

      mail :to => friend.befriendee.email,
           :subject => I18n.t("notifier.friend_notification.subject", :user => friend.befriender.display_name)
    end
  end

  def note_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @noteurl = browse_note_url(comment.note, :host => SERVER_URL)
      @place = Nominatim.describe_location(comment.note.lat, comment.note.lon, 14, I18n.locale)
      @comment = comment.body
      @owner = recipient == comment.note.author
      @event = comment.event

      @commenter = if comment.author
                     comment.author.display_name
                   else
                     I18n.t("notifier.note_comment_notification.anonymous")
                   end

      subject = if @owner
                  I18n.t("notifier.note_comment_notification.#{@event}.subject_own", :commenter => @commenter)
                else
                  I18n.t("notifier.note_comment_notification.#{@event}.subject_other", :commenter => @commenter)
                end

      mail :to => recipient.email, :subject => subject
    end
  end

  def changeset_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @root_url = root_url(:host => SERVER_URL)
      @changeset_url = changeset_url(comment.changeset, :host => SERVER_URL)
      @comment = comment.body
      @owner = recipient == comment.changeset.user
      @commenter = comment.author.display_name
      @commenter_url = user_url(comment.author.display_name, :host => SERVER_URL)
      @commenter_thumbnail_src = comment.author.image.url(:small, :host => SERVER_URL)
      @changeset_comment = comment.changeset.tags["comment"].presence
      @time = comment.created_at
      @changeset_author = comment.changeset.user.display_name

      subject = if @owner
                  I18n.t("notifier.changeset_comment_notification.commented.subject_own", :commenter => @commenter)
                else
                  I18n.t("notifier.changeset_comment_notification.commented.subject_other", :commenter => @commenter)
                end

      attachments.inline['osm_logo_30x30.png'] = {
        mime_type: 'image/png',
        encoding: 'base64',
        content: @@osm_logo_png_bytes,
      }

      mail :to => recipient.email, :subject => subject
    end
  end

  private

  def with_recipient_locale(recipient)
    I18n.with_locale Locale.available.preferred(recipient.preferred_languages) do
      yield
    end
  end

  def from_address(name, type, id, digest, user_id = nil)
    if Object.const_defined?(:MESSAGES_DOMAIN) && domain = MESSAGES_DOMAIN
      if user_id
        "#{name} <#{type}-#{id}-#{user_id}-#{digest[0, 6]}@#{domain}>"
      else
        "#{name} <#{type}-#{id}-#{digest[0, 6]}@#{domain}>"
      end
    else
      EMAIL_FROM
    end
  end

  # FIXME - 2016-12-28 - saintamh - someone please show me a better way to
  # include this blob in here. If I save it under app/assets, how do I get a
  # path to it in a portable way?
  @@osm_logo_png_bytes = <<EOS
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
EOS

end
