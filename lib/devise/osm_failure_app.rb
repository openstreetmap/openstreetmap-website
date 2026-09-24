# frozen_string_literal: true

require "devise/failure_app"

module Devise
  class OsmFailureApp < Devise::FailureApp
    def respond
      case failure_code
      when :unauthenticated
        redirect_to_retry_login
      when :password_expired
        flash[:warning] = I18n.t("sessions.new.reset_to_login")
        redirect_to user_forgot_password_url
      when :not_found_in_database, :invalid
        flash[:error] = I18n.t("sessions.new.auth failure")
        redirect_to_retry_login
      when :user_suspended
        flash[:error] = { :partial => "sessions/suspended_flash" }
        redirect_to_retry_login
        # TODO: session.delete(:remember_me)
      else
        super
      end
    end

    protected

    def failure_code
      message = warden_options[:message]
      action = warden_options[:action]
      if message.is_a?(Symbol)
        message
      elsif message.is_a?(Hash) && message.key?(:code)
        message[:code]
      elsif message.nil? && action == "unauthenticated"
        :unauthenticated
      else
        raise "Can't interpret warden_message (code): #{warden_options.inspect}"
      end
    end

    def failure_details
      message = warden_options[:message]
      action = warden_options[:action]
      if message.is_a?(Symbol)
        {}
      elsif message.is_a?(Hash) && message.key?(:code)
        message
      elsif message.nil? && action == "unauthenticated"
        { :referer => warden_options[:attempted_path] }
      else
        raise "Can't interpret warden_message (details): #{warden_options.inspect}"
      end
    end

    def redirect_to_retry_login
      redirect_to new_user_session_url(
        :referer => failure_details[:referer],
        :username => failure_details[:username] || params[:username],
        :remember_me => session[:remember_me]
      )
    end
  end
end
