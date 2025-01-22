class UserMailer < ApplicationMailer
  include ActionView::Helpers::AssetUrlHelper

  self.delivery_job = ActionMailer::MailDeliveryJob

  default :from => Settings.email_from,
          :return_path => Settings.email_return_path,
          :auto_submitted => "auto-generated"
  helper :application
  before_action :set_shared_template_vars
  before_action :attach_project_logo

  def signup_confirm(user, token, referer = nil)
    with_recipient_locale user do
      @url = url_for(:controller => "confirmations", :action => "confirm",
                     :display_name => user.display_name,
                     :confirm_string => token,
                     :referer => referer)

      mail :to => user.email,
           :subject => t(".subject")
    end
  end

  def email_confirm(user, token)
    with_recipient_locale user do
      @address = user.new_email
      @url = url_for(:controller => "confirmations", :action => "confirm_email",
                     :confirm_string => token)

      mail :to => user.new_email,
           :subject => t(".subject")
    end
  end

  def lost_password(user, token)
    with_recipient_locale user do
      @url = user_reset_password_url(:token => token)

      mail :to => user.email,
           :subject => t(".subject")
    end
  end

  def gpx_success(trace, possible_points)
    with_recipient_locale trace.user do
      @to_user = trace.user.display_name
      @trace_url = show_trace_url(trace.user, trace)
      @trace_name = trace.name
      @trace_points = trace.size
      @trace_description = trace.description
      @trace_tags = trace.tags
      @possible_points = possible_points
      @my_traces_url = url_for(:controller => "traces", :action => "mine")

      mail :to => trace.user.email,
           :subject => t(".subject")
    end
  end

  def gpx_failure(trace, error)
    with_recipient_locale trace.user do
      @to_user = trace.user.display_name
      @trace_name = trace.name
      @trace_description = trace.description
      @trace_tags = trace.tags
      @error = error

      mail :to => trace.user.email,
           :subject => t(".subject")
    end
  end

  def message_notification(message)
    with_recipient_locale message.recipient do
      @to_user = message.recipient.display_name
      @from_user = message.sender.display_name
      @text = message.body
      @title = message.title
      @readurl = message_url(message)
      @replyurl = new_message_reply_url(message)
      @author = @from_user

      attach_user_avatar(message.sender)

      mail :from => from_address(message.sender.display_name, "m", message.id, message.notification_token),
           :to => message.recipient.email,
           :subject => t(".subject", :message_title => message.title)
    end
  end

  def diary_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @to_user = recipient.display_name
      @from_user = comment.user.display_name
      @text = comment.body
      @title = comment.diary_entry.title
      @readurl = diary_entry_url(comment.diary_entry.user, comment.diary_entry, :anchor => "comment#{comment.id}")
      @commenturl = diary_entry_url(comment.diary_entry.user, comment.diary_entry, :anchor => "newcomment")
      @replyurl = new_message_url(comment.user, :message => { :title => "Re: #{comment.diary_entry.title}" })
      @unsubscribeurl = diary_entry_unsubscribe_url(comment.diary_entry.user, comment.diary_entry)
      @author = @from_user

      attach_user_avatar(comment.user)

      set_references("diary", comment.diary_entry)

      set_list_headers(
        "#{comment.diary_entry.id}.diary.www.openstreetmap.org",
        t(".description", :id => comment.diary_entry.id),
        :archive => @readurl,
        :subscribe => diary_entry_subscribe_url(comment.diary_entry.user, comment.diary_entry),
        :unsubscribe => @unsubscribeurl
      )

      mail :from => from_address(comment.user.display_name, "c", comment.id, comment.notification_token(recipient.id), recipient.id),
           :to => recipient.email,
           :subject => t(".subject", :user => comment.user.display_name)
    end
  end

  def follow_notification(follow)
    with_recipient_locale follow.following do
      @follow = follow
      @viewurl = user_url(@follow.follower)
      @followurl = follow_url(@follow.follower)
      @author = @follow.follower.display_name

      attach_user_avatar(@follow.follower)
      mail :to => follow.following.email,
           :subject => t(".subject", :user => follow.follower.display_name)
    end
  end

  def note_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @noteurl = note_url(comment.note)
      @place = Nominatim.describe_location(comment.note.lat, comment.note.lon, 14, I18n.locale)
      @comment = comment.body
      @owner = recipient == comment.note.author
      @event = comment.event

      @commenter = if comment.author
                     comment.author.display_name
                   else
                     t(".anonymous")
                   end

      @author = @commenter
      attach_user_avatar(comment.author)

      set_references("note", comment.note)

      set_list_headers(
        "#{comment.note.id}.note.www.openstreetmap.org",
        t(".description", :id => comment.note.id),
        :archive => @noteurl
      )

      subject = if @owner
                  t(".#{@event}.subject_own", :commenter => @commenter)
                else
                  t(".#{@event}.subject_other", :commenter => @commenter)
                end

      mail :to => recipient.email, :subject => subject
    end
  end

  def changeset_comment_notification(comment, recipient)
    with_recipient_locale recipient do
      @to_user = recipient.display_name
      @changeset_url = changeset_url(comment.changeset)
      @comment = comment.body
      @owner = recipient == comment.changeset.user
      @commenter = comment.author.display_name
      @changeset_comment = comment.changeset.tags["comment"].presence
      @time = comment.created_at
      @changeset_author = comment.changeset.user.display_name
      @changeset_subscription_url = changeset_subscription_url(comment.changeset)
      @author = @commenter

      subject = if @owner
                  t(".commented.subject_own", :commenter => @commenter)
                else
                  t(".commented.subject_other", :commenter => @commenter)
                end

      attach_user_avatar(comment.author)

      set_references("changeset", comment.changeset)

      set_list_headers(
        "#{comment.changeset.id}.changeset.www.openstreetmap.org",
        t(".description", :id => comment.changeset.id),
        :subscribe => @changeset_subscription_url,
        :unsubscribe => @changeset_subscription_url,
        :archive => @changeset_url
      )

      mail :to => recipient.email, :subject => subject
    end
  end

  private

  def set_shared_template_vars
    @root_url = root_url
  end

  def attach_project_logo
    attachments.inline["logo.png"] = Rails.root.join("app/assets/images/osm_logo_30.png").read
  end

  def attach_user_avatar(user)
    @avatar = user_avatar_filename(user)
    attachments.inline[@avatar] = user_avatar_file(user)
  end

  def user_avatar_filename(user)
    avatar = user&.avatar
    if avatar&.attached?
      case avatar.content_type
      when "image/png" then "avatar.png"
      when "image/jpeg" then "avatar.jpg"
      when "image/gif" then "avatar.gif"
      when "image/bmp" then "avatar.bmp"
      when "image/tiff" then "avatar.tif"
      when "image/svg+xml" then "avatar.svg"
      else "avatar"
      end
    else
      "avatar.png"
    end
  end

  def user_avatar_file(user)
    avatar = user&.avatar
    if avatar&.attached?
      if avatar.variable?
        avatar.variant(:resize_to_limit => [50, 50]).download
      else
        avatar.blob.download
      end
    else
      Rails.root.join("app/assets/images/avatar_small.png").read
    end
  end

  def with_recipient_locale(recipient, &)
    I18n.with_locale(Locale.available.preferred(recipient.preferred_languages), &)
  end

  def from_address(name, type, id, token, user_id = nil)
    if Settings.key?(:messages_domain) && domain = Settings.messages_domain
      if user_id
        "#{name} <#{type}-#{id}-#{user_id}-#{token}@#{domain}>"
      else
        "#{name} <#{type}-#{id}-#{token}@#{domain}>"
      end
    else
      Settings.email_from
    end
  end

  def set_references(scope, reference_object)
    ref = "osm-#{scope}-#{reference_object.id}@#{Settings.server_url}"

    headers["X-Entity-Ref-ID"] = ref
    headers["In-Reply-To"] = ref
    headers["References"] = ref
  end

  def set_list_headers(id, description, options = {})
    headers["List-ID"] = "#{description} <#{id}>"
    headers["List-Archive"] = "<#{options[:archive]}>" if options[:archive]
    headers["List-Subscribe"] = "<#{options[:subscribe]}>" if options[:subscribe]
    headers["List-Unsubscribe"] = "<#{options[:unsubscribe]}>" if options[:unsubscribe]
  end
end
