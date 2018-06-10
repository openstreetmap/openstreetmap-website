# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => "localhost",
  :port => 25,
  :domain => "localhost",
  :enable_starttls_auto => false
}

# Set the host and protocol for all ActionMailer URLs
ActionMailer::Base.default_url_options = {
  :host => SERVER_URL,
  :protocol => SERVER_PROTOCOL
}
