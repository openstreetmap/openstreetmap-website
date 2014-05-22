module GeocoderHelper
  def result_to_html(result)
    html_options = { :class => "set_position", :data => {} }

    if result[:type] and result[:id]
      url = url_for(:controller => :browse, :action => result[:type], :id => result[:id])
    elsif result[:min_lon] and result[:min_lat] and result[:max_lon] and result[:max_lat]
      url = "/?bbox=#{result[:min_lon]},#{result[:min_lat]},#{result[:max_lon]},#{result[:max_lat]}"
    else
      url = "/#map=#{result[:zoom]}/#{result[:lat]}/#{result[:lon]}"
    end

    result.each do |key,value|
      html_options[:data][key.to_s.tr('_', '-')] = value
    end

    html = ""
    html << result[:prefix] if result[:prefix]
    html << " " if result[:prefix] and result[:name]
    html << link_to(result[:name], url, html_options) if result[:name]
    html << result[:suffix] if result[:suffix]
    html.html_safe
  end

  def describe_location(lat, lon, zoom = nil, language = nil)
    Nominatim.describe_location(lat, lon, zoom, language)
  end
end
