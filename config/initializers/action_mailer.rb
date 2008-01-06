# Configure ActionMailer
ActionMailer::Base.smtp_settings = {
  :address  => "localhost",
  :port  => 25, 
  :domain  => 'localhost',
}
