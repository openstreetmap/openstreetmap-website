# frozen_string_literal: true

module OpenStreetMap
  module Rack
    class PolicyHeaders
      COOP_HEADER = "Cross-Origin-Opener-Policy"

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, response = @app.call(env)
        headers[COOP_HEADER] = "same-origin" unless headers.key?(COOP_HEADER)
        [status, headers, response]
      end
    end
  end
end

Rails.configuration.middleware.use OpenStreetMap::Rack::PolicyHeaders
