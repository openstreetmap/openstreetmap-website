# Configure queue to use for ActionMailer deliveries
ActionMailer::Base.deliver_later_queue_name = :mailers

# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => Settings.smtp_address,
  :port => Settings.smtp_port,
  :domain => Settings.smtp_domain,
  :enable_starttls_auto => Settings.smtp_enable_starttls_auto,
  :openssl_verify_mode => Settings.smtp_tls_verify_mode,
  :authentication => Settings.smtp_authentication,
  :user_name => Settings.smtp_user_name,
  :password => Settings.smtp_password
}

# Set the host and protocol for all ActionMailer URLs
ActionMailer::Base.default_url_options = {
  :host => Settings.server_url,
  :protocol => Settings.server_protocol
}
