class Notifier < ActionMailer::Base
  def signup_confirm(user, token)
    common_headers user
    subject "[OpenStreetMap] Confirm your email address"
    body :url => url_for(:host => SERVER_URL,
                         :controller => "user", :action => "confirm",
                         :confirm_string => token.token)
  end

  def email_confirm(user, token)
    common_headers user
    recipients user.new_email
    subject "[OpenStreetMap] Confirm your email address"
    body :address => user.new_email,
         :url => url_for(:host => SERVER_URL,
                         :controller => "user", :action => "confirm_email",
                         :confirm_string => token.token)
  end

  def lost_password(user, token)
    common_headers user
    subject "[OpenStreetMap] Password reset request"
    body :url => url_for(:host => SERVER_URL,
                         :controller => "user", :action => "reset_password",
                         :email => user.email, :token => token.token)
  end

  def reset_password(user, pass)
    common_headers user
    subject "[OpenStreetMap] Password reset"
    body :pass => pass
  end

  def gpx_success(trace, possible_points)
    common_headers trace.user
    subject "[OpenStreetMap] GPX Import success"
    body :trace_name => trace.name,
         :trace_points => trace.size,
         :trace_description => trace.description,
         :trace_tags => trace.tags,
         :possible_points => possible_points
  end

  def gpx_failure(trace, error)
    common_headers trace.user
    from "webmaster@openstreetmap.org"
    subject "[OpenStreetMap] GPX Import failure"
    body :trace_name => trace.name,
         :trace_description => trace.description,
         :trace_tags => trace.tags,
         :error => error
  end
  
  def message_notification(message)
    common_headers message.recipient
    subject "[OpenStreetMap] #{message.sender.display_name} sent you a new message"
    body :to_user => message.recipient.display_name,
         :from_user => message.sender.display_name,
         :body => message.body,
         :subject => message.title,
         :readurl => url_for(:host => SERVER_URL,
                             :controller => "message", :action => "read",
                             :message_id => message.id),
         :replyurl => url_for(:host => SERVER_URL,
                              :controller => "message", :action => "reply",
                              :message_id => message.id)
  end

  def diary_comment_notification(comment)
    common_headers comment.diary_entry.user
    subject "[OpenStreetMap] #{comment.user.display_name} commented on your diary entry"
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
                              :user_id => comment.user.id,
                              :title => "Re: #{comment.diary_entry.title}")
  end

  def friend_notification(friend)
    befriender = User.find_by_id(friend.user_id)
    befriendee = User.find_by_id(friend.friend_user_id)

    common_headers befriendee
    subject "[OpenStreetMap] #{befriender.display_name} added you as a friend"
    body :user => befriender.display_name,
         :userurl => url_for(:host => SERVER_URL,
                             :controller => "user", :action => "view",
                             :display_name => befriender.display_name)
  end

private

  def common_headers(recipient)
    recipients recipient.email
    locale recipient.preferred_language_from(I18n.available_locales)
    from "webmaster@openstreetmap.org"
    headers "return-path" => "bounces@openstreetmap.org",
            "Auto-Submitted" => "auto-generated"
  end
end
