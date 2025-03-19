if Rails.env.test?
  require "active_support/testing/parallelization"

  module OpenStreetMap
    module Selenium
      module BidiPort
        def initialize(config)
          super

          @extra_args = Array(@extra_args) << "--websocket-port=0"
        end
      end
    end
  end

  Selenium::WebDriver::ServiceManager.prepend(OpenStreetMap::Selenium::BidiPort)
end
