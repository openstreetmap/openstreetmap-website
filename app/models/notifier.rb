class Notifier < ActionMailer::Base

  def signup_confirm( user )
    @recipients = user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] Confirm your email address'
    @body['url'] = 'http://www.openstreetmap.org/user/confirm?confirm_string=' + user.token
  end

  def lost_password( user )
    @recipients = user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] Passwors reset request'
    @body['url'] = "http://www.openstreetmap.org/user/reset_password?email=#{user.email}&token=#{user.token}"
  end

end
