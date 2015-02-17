require 'oauth/rack/oauth_filter'

Rails.configuration.middleware.use OAuth::Rack::OAuthFilter

module OAuth
  module RequestProxy
    class RackRequest
      def method
        request.request_method
      end
    end
  end
end
