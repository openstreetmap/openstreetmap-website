if Rails.env.test?
  require "active_support/testing/parallelization"

  module OpenStreetMap
    module Selenium
      module BidiPort
        module ClassMethods
          attr_accessor :websocket_port
        end

        def self.prepended(base)
          class << base
            prepend ClassMethods
          end

          base.websocket_port = 10000

          ActiveSupport::Testing::Parallelization.after_fork_hook do |worker|
            base.websocket_port = 10000 + worker
          end
        end

        def initialize(config)
          super

          @extra_args = Array(@extra_args) << "--websocket-port=#{self.class.websocket_port}"

          self.class.websocket_port += 256
        end
      end
    end
  end

  Selenium::WebDriver::ServiceManager.prepend(OpenStreetMap::Selenium::BidiPort)
end
