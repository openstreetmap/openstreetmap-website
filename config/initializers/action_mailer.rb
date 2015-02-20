# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => "localhost",
  :port => 25,
  :domain => "localhost",
  :enable_starttls_auto => false
}
