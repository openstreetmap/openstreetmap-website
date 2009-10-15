module GeocoderHelper
  def result_to_html(result)
    html_options = {}
    #html_options[:title] = strip_tags(result[:description]) if result[:description]
    html_options[:href] = "?mlat=#{result[:lat]}&mlon=#{result[:lon]}&zoom=#{result[:zoom]}"
    html = ""
    html << result[:prefix] if result[:prefix]
    html << " " if result[:prefix] and result[:name]

    if result[:min_lon] and result[:min_lat] and result[:max_lon] and result[:max_lat]
      html << link_to_function(result[:name],"setPosition(#{result[:lat]}, #{result[:lon]}, #{result[:zoom]}, #{result[:min_lon]}, #{result[:min_lat]}, #{result[:max_lon]}, #{result[:max_lat]})", html_options)  if result[:name]
    else
      html << link_to_function(result[:name],"setPosition(#{result[:lat]}, #{result[:lon]}, #{result[:zoom]})", html_options)  if result[:name]
    end

    html << result[:suffix] if result[:suffix]
    return html
  end
end
