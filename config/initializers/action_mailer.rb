# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => 'localhost',
  :port => 25, 
  :domain => 'localhost',
}

# This will let you more easily use helpers based on url_for in your mailers.
ActionMailer::Base.default_url_options[:host] = APP_CONFIG['host']

# Monkey patch to fix return-path bug in ActionMailer 2.2.2
# Can be removed once we go to 2.3
module Net
  class SMTP
    def sendmail(msgstr, from_addr, *to_addrs)
      send_message(msgstr, from_addr.to_s.sub(/^<(.*)>$/, "\\1"), *to_addrs)
    end
  end
end
