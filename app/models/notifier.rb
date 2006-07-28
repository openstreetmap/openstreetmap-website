class Notifier < ActionMailer::Base

  def signup_confirm( user )
    # Email header info MUST be added here
    @recipients = user.email
    @from = 'abuse@openstreetmap.org'
    @subject = '[OpenStreetMap] Confirm your email address'

    @body['url'] = 'http://www.openstreetmap.org/user/confirm?confirm_string=' + user.token
  end
  
end
