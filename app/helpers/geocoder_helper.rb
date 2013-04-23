module GeocoderHelper
  def result_to_html(result)
    html_options = { :class => "set_position", :data => {} }

    if result[:min_lon] and result[:min_lat] and result[:max_lon] and result[:max_lat]
      url = "?minlon=#{result[:min_lon]}&minlat=#{result[:min_lat]}&maxlon=#{result[:max_lon]}&maxlat=#{result[:max_lat]}"
    else
      url = "?mlat=#{result[:lat]}&mlon=#{result[:lon]}&zoom=#{result[:zoom]}"
    end

    result.each do |key,value|
      html_options[:data][key.to_s.tr('_', '-')] = value
    end

    html = ""
    html << result[:prefix] if result[:prefix]
    html << " " if result[:prefix] and result[:name]
    html << link_to(result[:name], url, html_options) if result[:name]
    html << result[:suffix] if result[:suffix]

    return raw(html)
  end

  def describe_location(lat, lon, zoom = nil, language = nil)
    Nominatim.describe_location(lat, lon, zoom, language)
  end
end
