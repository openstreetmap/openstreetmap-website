# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => 'localhost',
  :port => 25, 
  :domain => 'localhost',
  :enable_starttls_auto => false
}

# Monkey patch to allow sending of messages in specific locales
module ActionMailer
  class Base
    adv_attr_accessor :locale

    def mail_with_locale(*args)
      old_locale= I18n.locale

      begin
        I18n.locale = @locale
        message = mail_without_locale(*args)
      ensure
        I18n.locale = old_locale
      end

      message
    end

    alias_method_chain :mail, :locale
  end
end
