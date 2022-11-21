module Nominatim
  require "timeout"

  extend ActionView::Helpers::NumberHelper

  def self.describe_location(lat, lon, zoom = nil, language = nil)
    zoom ||= 14
    language ||= http_accept_language.user_preferred_languages.join(",")

    Rails.cache.fetch "/nominatim/location/#{lat}/#{lon}/#{zoom}/#{language}" do
      url = "#{Settings.nominatim_url}reverse?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{language}"

      begin
        response = Timeout.timeout(4) do
          REXML::Document.new(Net::HTTP.get(URI.parse(url)))
        end
      rescue StandardError
        response = nil
      end

      if response && result = response.get_text("reversegeocode/result")
        result.value
      else
        "#{number_with_precision(lat, :precision => 3)}, #{number_with_precision(lon, :precision => 3)}"
      end
    end
  end
end
