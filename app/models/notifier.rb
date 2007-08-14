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
end
