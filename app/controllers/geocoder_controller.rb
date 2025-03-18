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
      @sources.push(:name => "latlon", :url => root_path)
      @sources.push(:name => "osm_nominatim_reverse", :url => nominatim_reverse_url(:format => "html"))
    elsif @params[:query]
      @sources.push(:name => "osm_nominatim", :url => nominatim_url(:format => "html"))
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

      if latlon = query.match(/^(?<ns>[NS])\s*#{dms_regexp('ns')}\W*(?<ew>[EW])\s*#{dms_regexp('ew')}$/) ||
                  query.match(/^#{dms_regexp('ns')}\s*(?<ns>[NS])\W*#{dms_regexp('ew')}\s*(?<ew>[EW])$/)
        params.merge!(to_decdeg(latlon.named_captures.compact)).delete(:query)

      elsif latlon = query.match(%r{^(?<lat>[+-]?\d+(?:\.\d+)?)(?:\s+|\s*[,/]\s*)(?<lon>[+-]?\d+(?:\.\d+)?)$})
        params.merge!(:lat => latlon["lat"], :lon => latlon["lon"]).delete(:query)

        params[:latlon_digits] = true
      end
    end

    params.permit(:query, :lat, :lon, :latlon_digits, :zoom, :minlat, :minlon, :maxlat, :maxlon)
  end

  def dms_regexp(name_prefix)
    /
      (?: (?<#{name_prefix}d>\d{1,3}(?:\.\d+)?)°? ) |
      (?: (?<#{name_prefix}d>\d{1,3})°?\s*(?<#{name_prefix}m>\d{1,2}(?:\.\d+)?)['′]? ) |
      (?: (?<#{name_prefix}d>\d{1,3})°?\s*(?<#{name_prefix}m>\d{1,2})['′]?\s*(?<#{name_prefix}s>\d{1,2}(?:\.\d+)?)["″]? )
    /x
  end

  def to_decdeg(captures)
    ns = captures.fetch("ns").casecmp?("s") ? -1 : 1
    nsd = BigDecimal(captures.fetch("nsd", "0"))
    nsm = BigDecimal(captures.fetch("nsm", "0"))
    nss = BigDecimal(captures.fetch("nss", "0"))

    ew = captures.fetch("ew").casecmp?("w") ? -1 : 1
    ewd = BigDecimal(captures.fetch("ewd", "0"))
    ewm = BigDecimal(captures.fetch("ewm", "0"))
    ews = BigDecimal(captures.fetch("ews", "0"))

    lat = ns * (nsd + (nsm / 60) + (nss / 3600))
    lon = ew * (ewd + (ewm / 60) + (ews / 3600))

    { :lat => lat.round(6).to_s("F"), :lon => lon.round(6).to_s("F") }
  end
end
