require "oauth/controllers/provider_controller"
require "oauth/rack/oauth_filter"

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

module OpenStreetMap
  module ProviderController
    def self.prepended(mod)
      mod.singleton_class.prepend(OpenStreetMap::ProviderController::ClassMethods)
    end

    def render(options = {})
      text = options.delete(:text)
      if text
        super options.merge(:plain => text)
      elsif options.delete(:nothing)
        status = options.delete(:status) || :ok
        head status, options
      else
        super options
      end
    end

    module ClassMethods
      def included(controller)
        controller.class_eval do
          def self.before_filter(*names, &blk)
            before_action(*names, &blk)
          end

          def self.skip_before_filter(*names, &blk)
            skip_before_action(*names, &blk)
          end
        end

        super controller
      end
    end
  end

  module OAuthFilter
    def oauth1_verify(request, options = {}, &block)
      signature = OAuth::Signature.build(request, options, &block)
      return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)

      value = signature.verify
      if request.ssl? && !value
        http_request = request.dup
        http_request.define_singleton_method(:scheme) { "http" }
        http_request.define_singleton_method(:port) { 80 }
        signature = OAuth::Signature.build(http_request, options, &block)
        value = signature.verify
      end
      value
    rescue OAuth::Signature::UnknownSignatureMethod
      false
    end
  end
end

OAuth::Controllers::ProviderController.prepend(OpenStreetMap::ProviderController)
OAuth::Rack::OAuthFilter.prepend(OpenStreetMap::OAuthFilter)
