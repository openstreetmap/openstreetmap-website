class GeocoderController < ApplicationController
  require "cgi"
  require "uri"
  require "rexml/document"

  before_action :authorize_web
  before_action :set_locale
  before_action :require_oauth, :only => [:search]
  authorize_resource :class => false

  def search
    @params = normalize_params
    @sources = []

    if @params[:lat] && @params[:lon]
      @sources.push "latlon"
      @sources.push "osm_nominatim_reverse"
    elsif @params[:query]
      @sources.push "osm_nominatim"
    end

    if @sources.empty?
      head :bad_request
    else
      render :layout => map_layout
    end
  end

  def search_latlon
    lat = params[:lat].to_f
    lon = params[:lon].to_f

    if params[:latlon_digits]
      # We've got two nondescript numbers for a query, which can mean both "lat, lon" or "lon, lat".
      @results = []

      if lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
        @results.push(:lat => lat, :lon => lon,
                      :zoom => params[:zoom],
                      :name => "#{lat}, #{lon}")
      end

      if lon >= -90 && lon <= 90 && lat >= -180 && lat <= 180
        @results.push(:lat => lon, :lon => lat,
                      :zoom => params[:zoom],
                      :name => "#{lon}, #{lat}")
      end

      if @results.empty?
        @error = "Latitude or longitude are out of range"
        render :action => "error"
      else
        render :action => "results"
      end
    else
      # Coordinates in a query have come with markers for latitude and longitude.
      if lat < -90 || lat > 90
        @error = "Latitude #{lat} out of range"
        render :action => "error"
      elsif lon < -180 || lon > 180
        @error = "Longitude #{lon} out of range"
        render :action => "error"
      else
        @results = [{ :lat => lat, :lon => lon,
                      :zoom => params[:zoom],
                      :name => "#{lat}, #{lon}" }]

        render :action => "results"
      end
    end
  end

  def search_osm_nominatim
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

    # ask nominatim
    response = fetch_xml("#{Settings.nominatim_url}search?format=xml&extratags=1&q=#{escape_query(query)}#{viewbox}#{exclude}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}")

    # extract the results from the response
    results =  response.elements["searchresults"]

    # extract parameters from more_url
    more_url_params = CGI.parse(URI.parse(results.attributes["more_url"]).query)

    # create result array
    @results = []

    # create parameter hash for "more results" link
    @more_params = params
                   .permit(:query, :minlon, :minlat, :maxlon, :maxlat, :exclude)
                   .merge(:exclude => more_url_params["exclude_place_ids"].first)

    # parse the response
    results.elements.each("place") do |place|
      lat = place.attributes["lat"]
      lon = place.attributes["lon"]
      klass = place.attributes["class"]
      type = place.attributes["type"]
      name = place.attributes["display_name"]
      min_lat, max_lat, min_lon, max_lon = place.attributes["boundingbox"].split(",")
      prefix_name = if type.empty?
                      ""
                    else
                      t "geocoder.search_osm_nominatim.prefix.#{klass}.#{type}", :default => type.tr("_", " ").capitalize
                    end
      if klass == "boundary" && type == "administrative"
        rank = (place.attributes["address_rank"].to_i + 1) / 2
        prefix_name = t "geocoder.search_osm_nominatim.admin_levels.level#{rank}", :default => prefix_name
        place.elements["extratags"].elements.each("tag") do |extratag|
          prefix_name = t "geocoder.search_osm_nominatim.prefix.place.#{extratag.attributes['value']}", :default => prefix_name if extratag.attributes["key"] == "linked_place" || extratag.attributes["key"] == "place"
        end
      end
      prefix = t ".prefix_format", :name => prefix_name
      object_type = place.attributes["osm_type"]
      object_id = place.attributes["osm_id"]

      @results.push(:lat => lat, :lon => lon,
                    :min_lat => min_lat, :max_lat => max_lat,
                    :min_lon => min_lon, :max_lon => max_lon,
                    :prefix => prefix, :name => name,
                    :type => object_type, :id => object_id)
    end

    render :action => "results"
  rescue StandardError => e
    host = URI(Settings.nominatim_url).host
    @error = "Error contacting #{host}: #{e}"
    render :action => "error"
  end

  def search_osm_nominatim_reverse
    # get query parameters
    lat = params[:lat]
    lon = params[:lon]
    zoom = params[:zoom]

    # create result array
    @results = []

    # ask nominatim
    response = fetch_xml("#{Settings.nominatim_url}reverse?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}")

    # parse the response
    response.elements.each("reversegeocode/result") do |result|
      lat = result.attributes["lat"]
      lon = result.attributes["lon"]
      object_type = result.attributes["osm_type"]
      object_id = result.attributes["osm_id"]
      description = result.text

      @results.push(:lat => lat, :lon => lon,
                    :zoom => zoom,
                    :name => description,
                    :type => object_type, :id => object_id)
    end

    render :action => "results"
  rescue StandardError => e
    host = URI(Settings.nominatim_url).host
    @error = "Error contacting #{host}: #{e}"
    render :action => "error"
  end

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

  def escape_query(query)
    CGI.escape(query)
  end

  def normalize_params
    if query = params[:query]
      query.strip!

      if latlon = query.match(/^([NS])\s*(\d{1,3}(\.\d*)?)\W*([EW])\s*(\d{1,3}(\.\d*)?)$/).try(:captures) || # [NSEW] decimal degrees
                  query.match(/^(\d{1,3}(\.\d*)?)\s*([NS])\W*(\d{1,3}(\.\d*)?)\s*([EW])$/).try(:captures)    # decimal degrees [NSEW]
        params.merge!(nsew_to_decdeg(latlon)).delete(:query)

      elsif latlon = query.match(/^([NS])\s*(\d{1,3})°?(?:\s*(\d{1,3}(\.\d*)?)?['′]?)?\W*([EW])\s*(\d{1,3})°?(?:\s*(\d{1,3}(\.\d*)?)?['′]?)?$/).try(:captures) || # [NSEW] degrees, decimal minutes
                     query.match(/^(\d{1,3})°?(?:\s*(\d{1,3}(\.\d*)?)?['′]?)?\s*([NS])\W*(\d{1,3})°?(?:\s*(\d{1,3}(\.\d*)?)?['′]?)?\s*([EW])$/).try(:captures)    # degrees, decimal minutes [NSEW]
        params.merge!(ddm_to_decdeg(latlon)).delete(:query)

      elsif latlon = query.match(/^([NS])\s*(\d{1,3})°?\s*(\d{1,2})['′]?(?:\s*(\d{1,3}(\.\d*)?)?["″]?)?\W*([EW])\s*(\d{1,3})°?\s*(\d{1,2})['′]?(?:\s*(\d{1,3}(\.\d*)?)?["″]?)?$/).try(:captures) || # [NSEW] degrees, minutes, decimal seconds
                     query.match(/^(\d{1,3})°?\s*(\d{1,2})['′]?(?:\s*(\d{1,3}(\.\d*)?)?["″]?)?\s*([NS])\W*(\d{1,3})°?\s*(\d{1,2})['′]?(?:\s*(\d{1,3}(\.\d*)?)?["″]?)?\s*([EW])$/).try(:captures)    # degrees, minutes, decimal seconds [NSEW]
        params.merge!(dms_to_decdeg(latlon)).delete(:query)

      elsif latlon = query.match(/^([+-]?\d+(\.\d*)?)(?:\s+|\s*,\s*)([+-]?\d+(\.\d*)?)$/)
        params.merge!(:lat => latlon[1].to_f, :lon => latlon[3].to_f).delete(:query)

        params[:latlon_digits] = true unless params[:whereami]
      end
    end

    params.permit(:query, :lat, :lon, :latlon_digits, :zoom, :minlat, :minlon, :maxlat, :maxlon)
  end

  def nsew_to_decdeg(captures)
    begin
      Float(captures[0])
      lat = captures[2].casecmp("s").zero? ? -captures[0].to_f : captures[0].to_f
      lon = captures[5].casecmp("w").zero? ? -captures[3].to_f : captures[3].to_f
    rescue StandardError
      lat = captures[0].casecmp("s").zero? ? -captures[1].to_f : captures[1].to_f
      lon = captures[3].casecmp("w").zero? ? -captures[4].to_f : captures[4].to_f
    end
    { :lat => lat, :lon => lon }
  end

  def ddm_to_decdeg(captures)
    begin
      Float(captures[0])
      lat = captures[3].casecmp("s").zero? ? -(captures[0].to_f + (captures[1].to_f / 60)) : captures[0].to_f + (captures[1].to_f / 60)
      lon = captures[7].casecmp("w").zero? ? -(captures[4].to_f + (captures[5].to_f / 60)) : captures[4].to_f + (captures[5].to_f / 60)
    rescue StandardError
      lat = captures[0].casecmp("s").zero? ? -(captures[1].to_f + (captures[2].to_f / 60)) : captures[1].to_f + (captures[2].to_f / 60)
      lon = captures[4].casecmp("w").zero? ? -(captures[5].to_f + (captures[6].to_f / 60)) : captures[5].to_f + (captures[6].to_f / 60)
    end
    { :lat => lat, :lon => lon }
  end

  def dms_to_decdeg(captures)
    begin
      Float(captures[0])
      lat = captures[4].casecmp("s").zero? ? -(captures[0].to_f + ((captures[1].to_f + (captures[2].to_f / 60)) / 60)) : captures[0].to_f + ((captures[1].to_f + (captures[2].to_f / 60)) / 60)
      lon = captures[9].casecmp("w").zero? ? -(captures[5].to_f + ((captures[6].to_f + (captures[7].to_f / 60)) / 60)) : captures[5].to_f + ((captures[6].to_f + (captures[7].to_f / 60)) / 60)
    rescue StandardError
      lat = captures[0].casecmp("s").zero? ? -(captures[1].to_f + ((captures[2].to_f + (captures[3].to_f / 60)) / 60)) : captures[1].to_f + ((captures[2].to_f + (captures[3].to_f / 60)) / 60)
      lon = captures[5].casecmp("w").zero? ? -(captures[6].to_f + ((captures[7].to_f + (captures[8].to_f / 60)) / 60)) : captures[6].to_f + ((captures[7].to_f + (captures[8].to_f / 60)) / 60)
    end
    { :lat => lat, :lon => lon }
  end
end
