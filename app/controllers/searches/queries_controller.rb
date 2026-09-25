# frozen_string_literal: true

module Searches
  class QueriesController < ApplicationController
    before_action :authorize_web
    before_action :set_locale
    authorize_resource :class => :search

    private

    def fetch_text(url)
      response = OSM.http_client.get(URI.parse(url))

      if response.success?
        response.body
      else
        raise response.status.to_s
      end
    end

    def fetch_xml(url)
      REXML::Document.new(fetch_text(url))
    end
  end
end
