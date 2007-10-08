class Notifier < ActionMailer::Base

  def signup_confirm( user, token )
    @recipients = user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] Confirm your email address'
    @body['url'] = "http://#{SERVER_URL}/user/confirm?confirm_string=#{token.token}"
  end

  def lost_password( user, token )
    @recipients = user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] Password reset request'
    @body['url'] = "http://#{SERVER_URL}/user/reset_password?email=#{user.email}&token=#{token.token}"
  end

  def reset_password(user, pass)
    @recipients = user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] Password reset'
    @body['pass'] = pass
  end

  def gpx_success(trace, possible_points)
    @recipients = trace.user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] GPX Import success'
    @body['trace_name'] = trace.name
    @body['trace_points'] = trace.size
    @body['possible_points'] = possible_points
  end

  def gpx_failure(trace, error)
    @recipients = trace.user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] GPX Import failure'
    @body['trace_name'] = trace.name
    @body['error'] = error
  end
  
  def message_notification(message)
    @recipients = message.recipient.email
    @from = 'abuse@openstreetmap.org'
    @subject = "[OpenStreetMap] #{message.sender.display_name} sent you a new message"
    @body['to_user'] = message.recipient.display_name
    @body['from_user'] = message.sender.display_name
    @body['body'] = message.body
    @body['subject'] = message.title
    @body['readurl'] = "http://#{SERVER_URL}/message/read/#{message.id}"
    @body['replyurl'] = "http://#{SERVER_URL}/message/new/#{message.from_user_id}"
  end

  def friend_notification(friend)
    @friend = User.find_by_id(friend.user_id)
    @new_friend = User.find_by_id(friend.friend_user_id)
    @recipients = @new_friend.email
    @from = 'abuse@openstreetmap.org'
    @subject = "[OpenStreetMap] #{@friend.display_name} added you as a friend"
    @body['user'] = @friend.display_name
    @body['userurl'] = "http://#{SERVER_URL}/user/#{@friend.display_name}"
  end
end
