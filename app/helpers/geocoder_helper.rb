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
    zoom = zoom || 14
    language = language || request.user_preferred_languages.join(',')
    url = "http://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{language}"

    begin
      response = OSM::Timer.timeout(4) do
        REXML::Document.new(Net::HTTP.get(URI.parse(url)))
      end
    rescue Exception
      response = nil
    end

    if response and result = response.get_text("reversegeocode/result")
      result.to_s
    else
      "#{number_with_precision(lat, :precision => 3)}, #{number_with_precision(lon, :precision => 3)}"
    end
  end

  def ddm_to_decdeg(captures)
    captures[0].downcase != 's' ? lat = captures[1].to_f + captures[2].to_f/60 : lat = -(captures[1].to_f + captures[2].to_f/60)
    captures[3].downcase != 'w' ? lon = captures[4].to_f + captures[5].to_f/60 : lat = -(captures[4].to_f + captures[5].to_f/60)
    return "#{number_with_precision(lat, :precision => 5)}, #{number_with_precision(lon, :precision => 5)}"
  end

  def dms_to_decdeg(captures)
    begin
      Float(captures[0])
      captures[3].downcase != 's' ? lat = captures[0].to_f + (captures[1].to_f + captures[2].to_f/60)/60 : lat = -(captures[0].to_f + (captures[1].to_f + captures[2].to_f/60)/60)
      captures[7].downcase != 'w' ? lon = captures[4].to_f + (captures[5].to_f + captures[6].to_f/60)/60 : lat = -(captures[4].to_f + (captures[5].to_f + captures[6].to_f/60)/60)
    rescue
      captures[0].downcase != 's' ? lat = captures[1].to_f + (captures[2].to_f + captures[3].to_f/60)/60 : lat = -(captures[1].to_f + (captures[2].to_f + captures[3].to_f/60)/60)
      captures[4].downcase != 'w' ? lon = captures[5].to_f + (captures[6].to_f + captures[7].to_f/60)/60 : lat = -(captures[5].to_f + (captures[6].to_f + captures[7].to_f/60)/60)
    end
    return "#{number_with_precision(lat, :precision => 5)}, #{number_with_precision(lon, :precision => 5)}"
  end

end
