class GeocoderController < ApplicationController
  require "cgi"
  require "uri"
  require "rexml/document"

  before_action :authorize_web
  before_action :set_locale
  before_action :require_oauth, :only => [:search]

  authorize_resource :class => false

  before_action :normalize_params, :only => [:search]

  def search
    @sources = []

    if params[:lat] && params[:lon]
      @sources.push(:name => "latlon", :url => root_path,
                    :fetch_url => url_for(params.permit(:lat, :lon, :latlon_digits, :zoom).merge(:action => "search_latlon")))
      @sources.push(:name => "osm_nominatim_reverse", :url => nominatim_reverse_url(:format => "html"),
                    :fetch_url => url_for(params.permit(:lat, :lon, :zoom).merge(:action => "search_osm_nominatim_reverse")))
    elsif params[:query]
      @sources.push(:name => "osm_nominatim", :url => nominatim_url(:format => "html"),
                    :fetch_url => url_for(params.permit(:query, :minlat, :minlon, :maxlat, :maxlon).merge(:action => "search_osm_nominatim")))
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

      if lat.between?(-90, 90) && lon.between?(-180, 180)
        @results.push(:lat => params[:lat], :lon => params[:lon],
                      :zoom => params[:zoom],
                      :name => "#{params[:lat]}, #{params[:lon]}")
      end

      if lon.between?(-90, 90) && lat.between?(-180, 180)
        @results.push(:lat => params[:lon], :lon => params[:lat],
                      :zoom => params[:zoom],
                      :name => "#{params[:lon]}, #{params[:lat]}")
      end

      if @results.empty?
        @error = "Latitude or longitude are out of range"
        render :action => "error"
      else
        render :action => "results"
      end
    else
      # Coordinates in a query have come with markers for latitude and longitude.
      if !lat.between?(-90, 90)
        @error = "Latitude #{lat} out of range"
        render :action => "error"
      elsif !lon.between?(-180, 180)
        @error = "Longitude #{lon} out of range"
        render :action => "error"
      else
        @results = [{ :lat => params[:lat], :lon => params[:lon],
                      :zoom => params[:zoom],
                      :name => "#{params[:lat]}, #{params[:lon]}" }]

        render :action => "results"
      end
    end
  end

  def search_osm_nominatim
    # ask nominatim
    response = fetch_xml(nominatim_url(:format => "xml"))

    # extract the results from the response
    results = response.elements["searchresults"]

    # create result array
    @results = []

    # create parameter hash for "more results" link
    @more_params = params
                   .permit(:query, :minlon, :minlat, :maxlon, :maxlat, :exclude)
                   .merge(:exclude => results.attributes["exclude_place_ids"])

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
        border_type = nil
        place_type = nil
        place_tags = %w[linked_place place]
        place.elements["extratags"].elements.each("tag") do |extratag|
          border_type = t "geocoder.search_osm_nominatim.border_types.#{extratag.attributes['value']}", :default => border_type if extratag.attributes["key"] == "border_type"
          place_type = t "geocoder.search_osm_nominatim.prefix.place.#{extratag.attributes['value']}", :default => place_type if place_tags.include?(extratag.attributes["key"])
        end
        prefix_name = place_type || border_type || prefix_name
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
    zoom = params[:zoom]

    # create result array
    @results = []

    # ask nominatim
    response = fetch_xml(nominatim_reverse_url(:format => "xml"))

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

  def nominatim_url(format: nil)
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
    "#{Settings.nominatim_url}search?format=#{format}&extratags=1&q=#{escape_query(query)}#{viewbox}#{exclude}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}"
  end

  def nominatim_reverse_url(format: nil)
    # get query parameters
    lat = params[:lat]
    lon = params[:lon]
    zoom = params[:zoom]

    # build url
    "#{Settings.nominatim_url}reverse?format=#{format}&lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}"
  end

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

      if match = query.match(/^(?<ns>[NS])\s*#{dms_regexp('ns')}\W*(?<ew>[EW])\s*#{dms_regexp('ew')}$/) ||
                 query.match(/^#{dms_regexp('ns')}\s*(?<ns>[NS])\W*#{dms_regexp('ew')}\s*(?<ew>[EW])$/)
        captures = match.named_captures.compact
        params.merge! :lat => dms_to_decdeg("ns", "ns", captures),
                      :lon => dms_to_decdeg("ew", "ew", captures)
        params.delete(:query)

      elsif match = query.match(%r{^
                      (?<ns>[+-]?)\s*#{dms_regexp('ns', :comma => false)}
                      (?:\s+|\s*[,/]\s*)
                      (?<ew>[+-]?)\s*#{dms_regexp('ew', :comma => false)}
                    $}x)
        captures = match.named_captures.compact
        params.merge! :lat => dms_to_decdeg("ns", "+-", captures),
                      :lon => dms_to_decdeg("ew", "+-", captures)
        params.delete(:query)
        params[:latlon_digits] = true
      end
    end
  end

  def dms_regexp(prefix, comma: true)
    final_fraction = comma ? /(?:[.,]\d+)?/ : /(?:[.]\d+)?/
    /
      (?: (?<#{prefix}d>\d{1,3}#{final_fraction})°? ) |
      (?: (?<#{prefix}d>\d{1,3})°?\s*(?<#{prefix}m>\d{1,2}#{final_fraction})['′]? ) |
      (?: (?<#{prefix}d>\d{1,3})°?\s*(?<#{prefix}m>\d{1,2})['′]?\s*(?<#{prefix}s>\d{1,2}#{final_fraction})["″]? )
    /x
  end

  def dms_to_decdeg(prefix, directions, captures)
    extract_number = ->(suffix) { captures.fetch("#{prefix}#{suffix}", "0").sub(",", ".") }

    positive_direction, negative_direction = directions.chars
    sign = captures.fetch(prefix, positive_direction).casecmp?(negative_direction) ? "-" : ""
    deg = if captures["#{prefix}m"] || captures["#{prefix}s"]
            d = BigDecimal extract_number.call("d")
            m = BigDecimal extract_number.call("m")
            s = BigDecimal extract_number.call("s")
            (d + (m / 60) + (s / 3600)).round(6).to_s("F")
          else
            extract_number.call("d")
          end
    "#{sign}#{deg}"
  end
end
