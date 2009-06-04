# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => 'localhost',
  :port => 25, 
  :domain => 'localhost',
}

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
