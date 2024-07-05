module GeocoderHelper
  def result_to_html(result)
    html_options = { :class => "set_position stretched-link", :data => {} }

    result.each do |key, value|
      if key.to_s == "name" && value.match(%r{^([+-]?\d+(\.\d*)?)(([eE][-+]?\d+)?)(?:\s+|\s*[,/]\s*)([+-]?\d+(\.\d*)?)(([eE][-+]?\d+)?)$})
        lat, lon = value.split(%r{[\/,]})

        if lat.index(".").positive?
          number_of_decimals = lat.length - lat.index(".") - 1
          lat = format("%0.#{number_of_decimals}f", lat.to_f)
        end

        if lon.index(".").positive?
          number_of_decimals = lon.length - lon.index(".") - 1
          lon = format("%0.#{number_of_decimals}f", lon.to_f)
        end

        value = "#{lat}, #{lon}"
        result[key] = value
      elsif key.to_s == "lat" || key.to_s == "lon"
        if value.to_f.abs < 0.0001
          value_str = value.to_s

          if value_str.index(".").positive?
            number_of_decimals = value_str.length - value_str.index(".") - 1
            value = format("%0.#{number_of_decimals}f", value.to_f)
            result[key] = value
          end
        end
      end

      html_options[:data][key.to_s.tr("_", "-")] = value
    end

    url = if result[:type] && result[:id]
            url_for(:controller => result[:type].pluralize, :action => :show, :id => result[:id])
          elsif result[:min_lon] && result[:min_lat] && result[:max_lon] && result[:max_lat]
            "/?bbox=#{result[:min_lon]},#{result[:min_lat]},#{result[:max_lon]},#{result[:max_lat]}"
          else
            "/#map=#{result[:zoom]}/#{result[:lat]}/#{result[:lon]}"
          end

    html = []
    html << result[:prefix] if result[:prefix]
    html << " " if result[:prefix] && result[:name]
    html << link_to(result[:name], url, html_options) if result[:name]
    html << " " if result[:suffix] && result[:name]
    html << result[:suffix] if result[:suffix]
    safe_join(html)
  end

  def describe_location(lat, lon, zoom = nil, language = nil)
    Nominatim.describe_location(lat, lon, zoom, language)
  end
end
