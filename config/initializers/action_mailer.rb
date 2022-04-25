# Configure queue to use for ActionMailer deliveries
ActionMailer::Base.deliver_later_queue_name = :mailers

# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => ENV["SMTP_ADDRESS"] || "localhost",
  :user_name => ENV["SMTP_USER"],
  :password => ENV["SMTP_PASSWORD"],
  :authentication => :login,
  :port => ENV["SMTP_PORT"] || 25,
  :domain => "localhost",
  :enable_starttls_auto => true
}

# Set the host and protocol for all ActionMailer URLs
ActionMailer::Base.default_url_options = {
  :host => Settings.server_url,
  :protocol => Settings.server_protocol
}
