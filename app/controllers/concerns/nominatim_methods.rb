module NominatimMethods
  extend ActiveSupport::Concern

  private

  def nominatim_query_url(format: nil)
    # get query parameters
    query = params[:query]
    minlon = params[:minlon]
    minlat = params[:minlat]
    maxlon = params[:maxlon]
    maxlat = params[:maxlat]

    # get view box
    viewbox = "&viewbox=#{minlon},#{maxlat},#{maxlon},#{minlat}" if minlon && minlat && maxlon && maxlat

    # get objects to excude
    exclude = "&exclude_place_ids=#{params[:exclude]}" if params[:exclude]

    # build url
    "#{Settings.nominatim_url}search?format=#{format}&extratags=1&q=#{CGI.escape(query)}#{viewbox}#{exclude}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}"
  end

  def nominatim_reverse_query_url(format: nil)
    # get query parameters
    lat = params[:lat]
    lon = params[:lon]
    zoom = params[:zoom]

    # build url
    "#{Settings.nominatim_url}reverse?format=#{format}&lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}"
  end
end
