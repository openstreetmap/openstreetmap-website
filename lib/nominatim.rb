module Nominatim
  require "timeout"

  extend ActionView::Helpers::NumberHelper

  def self.describe_location(lat, lon, zoom = nil, language = nil)
    zoom ||= 14
    language ||= http_accept_language.user_preferred_languages.join(",")

    Rails.cache.fetch "/nominatim/location/#{lat}/#{lon}/#{zoom}/#{language}" do
      url = "#{Settings.nominatim_url}reverse?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{language}"

      begin
        response = OSM.http_client.get(URI.parse(url)) do |request|
          request.options.timeout = 4
        end

        results = REXML::Document.new(response.body) if response.success?
      rescue StandardError
        results = nil
      end

      if results && result = results.get_text("reversegeocode/result")
        result.value
      else
        "#{number_with_precision(lat, :precision => 3)}, #{number_with_precision(lon, :precision => 3)}"
      end
    end
  end
end
