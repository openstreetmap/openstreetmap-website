require 'oauth/rack/oauth_filter'
require 'oauth2'

Rails.configuration.middleware.use OAuth::Rack::OAuthFilter

module OAuth::RequestProxy
  class RackRequest
    def method
      request.request_method
    end
  end
end
