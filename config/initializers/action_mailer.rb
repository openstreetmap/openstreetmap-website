# Configure ActionMailer SMTP settings
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

# Monkey patch to allow sending of messages in specific locales
module ActionMailer
  class Base
    adv_attr_accessor :locale
  private
    alias_method :old_render_message, :render_message

    def render_message(method_name, body)
      old_locale= I18n.locale

      begin
        I18n.locale = @locale
        message = old_render_message(method_name, body)
      ensure
        I18n.locale = old_locale
      end

      message
    end
  end
end
