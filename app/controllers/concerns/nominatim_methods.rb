# frozen_string_literal: true

module NominatimMethods
  extend ActiveSupport::Concern

  private

  def nominatim_url(method, parameters)
    url = URI.join(Settings.nominatim_url, method)
    url.query = parameters.merge("accept-language" => preferred_languages.join(",")).to_query
    url
  end

  def nominatim_query_url(format: nil)
    # get query parameters
    query = params[:query]
    minlon = params[:minlon]
    minlat = params[:minlat]
    maxlon = params[:maxlon]
    maxlat = params[:maxlat]

    # get nominatim parameters
    parameters = {
      "format" => format,
      "extratags" => 1,
      "q" => query
    }

    # add any view box
    parameters["viewbox"] = "#{minlon},#{maxlat},#{maxlon},#{minlat}" if minlon && minlat && maxlon && maxlat

    # add any objects to excude
    parameters["exclude_place_ids"] = params[:exclude] if params[:exclude]

    # build url
    nominatim_url("search", parameters)
  end

  def nominatim_reverse_query_url(format: nil)
    # get query parameters
    lat = params[:lat]
    lon = params[:lon]
    zoom = params[:zoom]

    # get nominatim parameters
    parameters = {
      "format" => format,
      "lat" => lat,
      "lon" => lon,
      "zoom" => zoom
    }

    # build url
    nominatim_url("reverse", parameters)
  end
end
