require "devise/failure_app"

module Devise
  class OsmFailureApp < Devise::FailureApp
    def respond
      pp ["OsmFailureApp#respond", warden_options]
      case failure_code
      when :not_found_in_database
        redirect
      when :user_suspended
        flash[:error] = { :partial => "sessions/suspended_flash" }
        redirect
        # TODO: session.delete(:remember_me)
      else
        super
      end
    end

    protected

    def redirect_url
      case failure_code
      when :not_found_in_database
        new_user_session_url
      when :user_suspended
        new_user_session_url(
          :referer => failure_details[:referer],
          :username => failure_details[:username],
          :remember_me => session[:remember_me]
        )
      else
        super
      end
    end

    def failure_code
      message = warden_options[:message]
      if message.is_a?(Symbol)
        message
      elsif message.is_a?(Hash) && message.key?(:code)
        message[:code]
      else
        raise "Can't interpret warden_message (code): #{warden_options.inspect}"
      end
    end

    def failure_details
      message = warden_options[:message]
      if message.is_a?(Symbol)
        {}
      elsif message.is_a?(Hash) && message.key?(:code)
        message
      else
        raise "Can't interpret warden_message (details): #{warden_options.inspect}"
      end
    end
  end
end
