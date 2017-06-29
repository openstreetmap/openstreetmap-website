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
end

OAuth::Controllers::ProviderController.prepend(OpenStreetMap::ProviderController)
