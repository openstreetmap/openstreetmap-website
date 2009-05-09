# Configure ActionMailer
ActionMailer::Base.smtp_settings = {
  :address => 'localhost',
  :port => 25, 
  :domain => 'localhost',
}

# Monkey patch to fix return-path bug in ActionMailer 2.2.2
# Can be removed once we go to 2.3
module Net
  class SMTP
    def sendmail(msgstr, from_addr, *to_addrs)
      send_message(msgstr, from_addr.to_s.sub(/^<(.*)>$/, "\\1"), *to_addrs)
    end
  end
end
