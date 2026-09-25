require "devise/failure_app"

module Devise
  class OsmFailureApp < Devise::FailureApp
    def respond
      pp ["OsmFailureApp#respond", warden_options]
      case warden_message
      when :not_found_in_database
        redirect
      else
        super
      end
    end

    protected

    def redirect_url
      case warden_message
      when :not_found_in_database
        new_user_session_url
      else
        super
      end
    end

    def warden_message
      warden_options[:message]
    end
  end
end
