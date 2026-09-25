# frozen_string_literal: true

module OpenStreetMap
  module OmniAuth
    module Strategies
      module OAuth2
        def callback_phase
          if request.request_method == "POST"
            query = URI.encode_www_form(request.params)
            uri = URI::Generic.build(:path => callback_path, :query => query)

            session.options[:skip] = true

            [303, { "Location" => uri.to_s }, []]
          else
            super
          end
        end
      end
    end
  end
end

OmniAuth::Strategies::OAuth2.prepend(OpenStreetMap::OmniAuth::Strategies::OAuth2)
