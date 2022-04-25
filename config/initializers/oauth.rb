require "oauth/controllers/provider_controller"
require "oauth/helper"
require "oauth/rack/oauth_filter"

Rails.configuration.middleware.use OAuth::Rack::OAuthFilter

module OAuth
  module Helper
    def escape(value)
      value.to_s.gsub(OAuth::RESERVED_CHARACTERS) do |c|
        c.bytes.map do |b|
          format("%%%02X", b)
        end.join
      end.force_encoding(Encoding::US_ASCII)
    end

    def unescape(value)
      value.to_s.gsub(/%\h{2}/) do |c|
        c[1..].to_i(16).chr
      end.force_encoding(Encoding::UTF_8)
    end
  end

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
      super
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
          def self.before_filter(...)
            before_action(...)
          end

          def self.skip_before_filter(...)
            skip_before_action(...)
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
