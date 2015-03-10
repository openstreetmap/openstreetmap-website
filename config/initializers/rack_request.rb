# Hack to workaround https://github.com/phusion/passenger/issues/1421
if defined?(PhusionPassenger)
  module Rack
    class Request
      def port
        DEFAULT_PORTS[scheme]
      end
    end
  end
end
