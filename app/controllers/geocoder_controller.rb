# coding: utf-8

class GeocoderController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'rexml/document'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :convert_latlon, :only => [:search]

  def search
    @query = params[:query]
    @sources = Array.new

    @query.sub(/^\s+/, "")
    @query.sub(/\s+$/, "")

    if @query.match(/^[+-]?\d+(\.\d*)?\s*[\s,]\s*[+-]?\d+(\.\d*)?$/)
      @sources.push "latlon"
    elsif @query.match(/^\d{5}(-\d{4})?$/)
      @sources.push "us_postcode"
      @sources.push "osm_nominatim"
    elsif @query.match(/^(GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW])\s*[0-9][ABD-HJLNP-UW-Z]{2})$/i)
      @sources.push "uk_postcode"
      @sources.push "osm_nominatim"
    elsif @query.match(/^[A-Z]\d[A-Z]\s*\d[A-Z]\d$/i)
      @sources.push "ca_postcode"
      @sources.push "osm_nominatim"
    else
      @sources.push "osm_nominatim"
      @sources.push "geonames" if defined?(GEONAMES_USERNAME)
    end
  end

  def search_latlon
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # decode the location
    if m = query.match(/^\s*([+-]?\d+(\.\d*)?)\s*[\s,]\s*([+-]?\d+(\.\d*)?)\s*$/)
      lat = m[1].to_f
      lon = m[3].to_f
    end

    # generate results
    if lat < -90 or lat > 90
      @error = "Latitude #{lat} out of range"
      render :action => "error"
    elsif lon < -180 or lon > 180
      @error = "Longitude #{lon} out of range"
      render :action => "error"
    else
      @results.push({:lat => lat, :lon => lon,
                     :zoom => POSTCODE_ZOOM,
                     :name => "#{lat}, #{lon}"})

      render :action => "results"
    end
  end

  def search_us_postcode
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # ask geocoder.us (they have a non-commercial use api)
    response = fetch_text("http://rpc.geocoder.us/service/csv?zip=#{escape_query(query)}")

    # parse the response
    unless response.match(/couldn't find this zip/)
      data = response.split(/\s*,\s+/) # lat,long,town,state,zip
      @results.push({:lat => data[0], :lon => data[1],
                     :zoom => POSTCODE_ZOOM,
                     :prefix => "#{data[2]}, #{data[3]},",
                     :name => data[4]})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting rpc.geocoder.us: #{ex.to_s}"
    render :action => "error"
  end

  def search_uk_postcode
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # ask npemap.org.uk to do a combined npemap + freethepostcode search
    response = fetch_text("http://www.npemap.org.uk/cgi/geocoder.fcgi?format=text&postcode=#{escape_query(query)}")

    # parse the response
    unless response.match(/Error/)
      dataline = response.split(/\n/)[1]
      data = dataline.split(/,/) # easting,northing,postcode,lat,long
      postcode = data[2].gsub(/'/, "")
      zoom = POSTCODE_ZOOM - postcode.count("#")
      @results.push({:lat => data[3], :lon => data[4], :zoom => zoom,
                     :name => postcode})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting www.npemap.org.uk: #{ex.to_s}"
    render :action => "error"
  end

  def search_ca_postcode
    # get query parameters
    query = params[:query]
    @results = Array.new

    # ask geocoder.ca (note - they have a per-day limit)
    response = fetch_xml("http://geocoder.ca/?geoit=XML&postal=#{escape_query(query)}")

    # parse the response
    if response.get_elements("geodata/error").empty?
      @results.push({:lat => response.get_text("geodata/latt").to_s,
                     :lon => response.get_text("geodata/longt").to_s,
                     :zoom => POSTCODE_ZOOM,
                     :name => query.upcase})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting geocoder.ca: #{ex.to_s}"
    render :action => "error"
  end

  def search_osm_nominatim
    # get query parameters
    query = params[:query]
    minlon = params[:minlon]
    minlat = params[:minlat]
    maxlon = params[:maxlon]
    maxlat = params[:maxlat]

    # get view box
    if minlon && minlat && maxlon && maxlat
      viewbox = "&viewbox=#{minlon},#{maxlat},#{maxlon},#{minlat}"
    end

    # get objects to excude
    if params[:exclude]
      exclude = "&exclude_place_ids=#{params[:exclude].join(',')}"
    end

    # ask nominatim
    response = fetch_xml("#{NOMINATIM_URL}search?format=xml&q=#{escape_query(query)}#{viewbox}#{exclude}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}")

    # create result array
    @results = Array.new

    # create parameter hash for "more results" link
    @more_params = params.reverse_merge({ :exclude => [] })

    # extract the results from the response
    results =  response.elements["searchresults"]

    # parse the response
    results.elements.each("place") do |place|
      lat = place.attributes["lat"].to_s
      lon = place.attributes["lon"].to_s
      klass = place.attributes["class"].to_s
      type = place.attributes["type"].to_s
      name = place.attributes["display_name"].to_s
      min_lat,max_lat,min_lon,max_lon = place.attributes["boundingbox"].to_s.split(",")
      prefix_name = t "geocoder.search_osm_nominatim.prefix.#{klass}.#{type}", :default => type.gsub("_", " ").capitalize
      if klass == 'boundary' and type == 'administrative'
        rank = (place.attributes["place_rank"].to_i + 1) / 2
        prefix_name = t "geocoder.search_osm_nominatim.admin_levels.level#{rank}", :default => prefix_name
      end
      prefix = t "geocoder.search_osm_nominatim.prefix_format", :name => prefix_name
      object_type = place.attributes["osm_type"]
      object_id = place.attributes["osm_id"]

      @results.push({:lat => lat, :lon => lon,
                     :min_lat => min_lat, :max_lat => max_lat,
                     :min_lon => min_lon, :max_lon => max_lon,
                     :prefix => prefix, :name => name,
                     :type => object_type, :id => object_id})
      @more_params[:exclude].push(place.attributes["place_id"].to_s)
    end

    render :action => "results"
#  rescue Exception => ex
#    @error = "Error contacting nominatim.openstreetmap.org: #{ex.to_s}"
#    render :action => "error"
  end

  def search_geonames
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # ask geonames.org
    response = fetch_xml("http://api.geonames.org/search?q=#{escape_query(query)}&maxRows=20&username=#{GEONAMES_USERNAME}")

    # parse the response
    response.elements.each("geonames/geoname") do |geoname|
      lat = geoname.get_text("lat").to_s
      lon = geoname.get_text("lng").to_s
      name = geoname.get_text("name").to_s
      country = geoname.get_text("countryName").to_s
      @results.push({:lat => lat, :lon => lon,
                     :zoom => GEONAMES_ZOOM,
                     :name => name,
                     :suffix => ", #{country}"})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting ws.geonames.org: #{ex.to_s}"
    render :action => "error"
  end

  def description
    @sources = Array.new

    @sources.push({ :name => "osm_nominatim" })
    @sources.push({ :name => "geonames" })
  end

  def description_osm_nominatim
    # get query parameters
    lat = params[:lat]
    lon = params[:lon]
    zoom = params[:zoom]

    # create result array
    @results = Array.new

    # ask nominatim
    response = fetch_xml("#{NOMINATIM_URL}reverse?lat=#{lat}&lon=#{lon}&zoom=#{zoom}&accept-language=#{http_accept_language.user_preferred_languages.join(',')}")

    # parse the response
    response.elements.each("reversegeocode/result") do |result|
      description = result.get_text.to_s

      @results.push({:prefix => "#{description}"})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting nominatim.openstreetmap.org: #{ex.to_s}"
    render :action => "error"
  end

  def description_geonames
    # get query parameters
    lat = params[:lat]
    lon = params[:lon]

    # create result array
    @results = Array.new

    # ask geonames.org
    response = fetch_xml("http://ws.geonames.org/countrySubdivision?lat=#{lat}&lng=#{lon}")

    # parse the response
    response.elements.each("geonames/countrySubdivision") do |geoname|
      name = geoname.get_text("adminName1").to_s
      country = geoname.get_text("countryName").to_s
      @results.push({:prefix => "#{name}, #{country}"})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting ws.geonames.org: #{ex.to_s}"
    render :action => "error"
  end

private

  def fetch_text(url)
    return Net::HTTP.get(URI.parse(url))
  end

  def fetch_xml(url)
    return REXML::Document.new(fetch_text(url))
  end

  def format_distance(distance)
    return t("geocoder.distance", :count => distance)
  end

  def format_direction(bearing)
    return t("geocoder.direction.south_west") if bearing >= 22.5 and bearing < 67.5
    return t("geocoder.direction.south") if bearing >= 67.5 and bearing < 112.5
    return t("geocoder.direction.south_east") if bearing >= 112.5 and bearing < 157.5
    return t("geocoder.direction.east") if bearing >= 157.5 and bearing < 202.5
    return t("geocoder.direction.north_east") if bearing >= 202.5 and bearing < 247.5
    return t("geocoder.direction.north") if bearing >= 247.5 and bearing < 292.5
    return t("geocoder.direction.north_west") if bearing >= 292.5 and bearing < 337.5
    return t("geocoder.direction.west")
  end

  def format_name(name)
    return name.gsub(/( *\[[^\]]*\])*$/, "")
  end

  def count_results(results)
    count = 0

    results.each do |source|
      count += source[:results].length if source[:results]
    end

    return count
  end

  def escape_query(query)
    return URI.escape(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]", false, 'N'))
  end

  def convert_latlon
    @query = params[:query]

    if latlon = @query.match(/^([NS])\s*(\d{1,3}(\.\d*)?)\W*([EW])\s*(\d{1,3}(\.\d*)?)$/).try(:captures) # [NSEW] decimal degrees
      params[:query] = nsew_to_decdeg(latlon)
    elsif latlon = @query.match(/^(\d{1,3}(\.\d*)?)\s*([NS])\W*(\d{1,3}(\.\d*)?)\s*([EW])$/).try(:captures) # decimal degrees [NSEW]
      params[:query] = nsew_to_decdeg(latlon)

    elsif latlon = @query.match(/^([NS])\s*(\d{1,3})°?\s*(\d{1,3}(\.\d*)?)?['′]?\W*([EW])\s*(\d{1,3})°?\s*(\d{1,3}(\.\d*)?)?['′]?$/).try(:captures) # [NSEW] degrees, decimal minutes
      params[:query] = ddm_to_decdeg(latlon)
    elsif latlon = @query.match(/^(\d{1,3})°?\s*(\d{1,3}(\.\d*)?)?['′]?\s*([NS])\W*(\d{1,3})°?\s*(\d{1,3}(\.\d*)?)?['′]?\s*([EW])$/).try(:captures) # degrees, decimal minutes [NSEW]
      params[:query] = ddm_to_decdeg(latlon)

    elsif latlon = @query.match(/^([NS])\s*(\d{1,3})°?\s*(\d{1,2})['′]?\s*(\d{1,3}(\.\d*)?)?["″]?\W*([EW])\s*(\d{1,3})°?\s*(\d{1,2})['′]?\s*(\d{1,3}(\.\d*)?)?["″]?$/).try(:captures) # [NSEW] degrees, minutes, decimal seconds
      params[:query] = dms_to_decdeg(latlon)
    elsif latlon = @query.match(/^(\d{1,3})°?\s*(\d{1,2})['′]?\s*(\d{1,3}(\.\d*)?)?["″]\s*([NS])\W*(\d{1,3})°?\s*(\d{1,2})['′]?\s*(\d{1,3}(\.\d*)?)?["″]?\s*([EW])$/).try(:captures) # degrees, minutes, decimal seconds [NSEW]
      params[:query] = dms_to_decdeg(latlon)
    else
      return
    end
  end

  def nsew_to_decdeg(captures)
    begin
      Float(captures[0])
      captures[2].downcase != 's' ? lat = captures[0].to_f : lat = -(captures[0].to_f)
      captures[5].downcase != 'w' ? lon = captures[3].to_f : lon = -(captures[3].to_f)
    rescue
      captures[0].downcase != 's' ? lat = captures[1].to_f : lat = -(captures[1].to_f)
      captures[3].downcase != 'w' ? lon = captures[4].to_f : lon = -(captures[4].to_f)
    end
    return "#{lat}, #{lon}"
  end

  def ddm_to_decdeg(captures)
    begin
      Float(captures[0])
      captures[3].downcase != 's' ? lat = captures[0].to_f + captures[1].to_f/60 : lat = -(captures[0].to_f + captures[1].to_f/60)
      captures[7].downcase != 'w' ? lon = captures[4].to_f + captures[5].to_f/60 : lon = -(captures[4].to_f + captures[5].to_f/60)
    rescue
      captures[0].downcase != 's' ? lat = captures[1].to_f + captures[2].to_f/60 : lat = -(captures[1].to_f + captures[2].to_f/60)
      captures[4].downcase != 'w' ? lon = captures[5].to_f + captures[6].to_f/60 : lon = -(captures[5].to_f + captures[6].to_f/60)
    end
    return "#{lat}, #{lon}"
  end

  def dms_to_decdeg(captures)
    begin
      Float(captures[0])
      captures[4].downcase != 's' ? lat = captures[0].to_f + (captures[1].to_f + captures[2].to_f/60)/60 : lat = -(captures[0].to_f + (captures[1].to_f + captures[2].to_f/60)/60)
      captures[9].downcase != 'w' ? lon = captures[5].to_f + (captures[6].to_f + captures[7].to_f/60)/60 : lon = -(captures[5].to_f + (captures[6].to_f + captures[7].to_f/60)/60)
    rescue
      captures[0].downcase != 's' ? lat = captures[1].to_f + (captures[2].to_f + captures[3].to_f/60)/60 : lat = -(captures[1].to_f + (captures[2].to_f + captures[3].to_f/60)/60)
      captures[5].downcase != 'w' ? lon = captures[6].to_f + (captures[7].to_f + captures[8].to_f/60)/60 : lon = -(captures[6].to_f + (captures[7].to_f + captures[8].to_f/60)/60)
    end
    return "#{lat}, #{lon}"
  end

end
