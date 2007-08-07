class GeocoderController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'rexml/document'

  def search
    @query = params[:query]
    @results = Array.new

    if @query.match(/^\d{5}(-\d{4})?$/)
      @results.push search_us_postcode(@query)
    elsif @query.match(/(GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW])\s*[0-9][ABD-HJLNP-UW-Z]{2})/i)
      @results.push search_uk_postcode(@query)
    elsif @query.match(/[A-Z]\d[A-Z]\s*\d[A-Z]\d/i)
      @results.push search_ca_postcode(@query)
    else
      @results.push search_osm_namefinder(@query)
      @results.push search_geonames(@query)
    end
  end

private

  def search_us_postcode(query)
    results = Array.new

    # ask geocoder.us (they have a non-commercial use api)
    response = fetch_text("http://rpc.geocoder.us/service/csv?zip=#{URI.escape(query)}")

    # parse the response
    unless response.match(/couldn't find this zip/)
      data = response.split(/\s*,\s+/) # lat,long,town,state,zip
      results.push({:lat => data[0], :lon => data[1], :zoom => 12,
                    :description => "#{data[2]}, #{data[3]}, #{data[4]}"})
    end

    return { :source => "Geocoder.us", :url => "http://geocoder.us/", :results => results }
  rescue Exception => ex
    return { :source => "Geocoder.us", :url => "http://geocoder.us/", :error => "Error contacting rpc.geocoder.us: #{ex.to_s}" }
  end

  def search_uk_postcode(query)
    results = Array.new

    # ask npemap.org.uk to do a combined npemap + freethepostcode search
    response = fetch_text("http://www.npemap.org.uk/cgi/geocoder.fcgi?format=text&postcode=#{URI.escape(query)}")

    # parse the response
    unless response.match(/Error/)
      dataline = response.split(/\n/)[1]
      data = dataline.split(/,/) # easting,northing,postcode,lat,long
      results.push({:lat => data[3], :lon => data[4], :zoom => 12,
                    :description => data[2].gsub(/'/, "")})
    end

    return { :source => "NPEMap / FreeThePostcode", :url => "http://www.npemap.org.uk/", :results => results }
  rescue Exception => ex
    return { :source => "NPEMap / FreeThePostcode", :url => "http://www.npemap.org.uk/", :error => "Error contacting www.npemap.org.uk: #{ex.to_s}" }
  end

  def search_ca_postcode(query)
    results = Array.new

    # ask geocoder.ca (note - they have a per-day limit)
    response = fetch_xml("http://geocoder.ca/?geoit=XML&postal=#{URI.escape(query)}")

    # parse the response
    unless response.get_elements("geodata/error")
      results.push({:lat => response.get_text("geodata/latt").to_s,
                    :lon => response.get_text("geodata/longt").to_s,
                    :zoom => 12,
                    :description => query.upcase})
    end

    return { :source => "Geocoder.CA", :url => "http://geocoder.ca/", :results => results }
  rescue Exception => ex
    return { :source => "Geocoder.CA", :url => "http://geocoder.ca/", :error => "Error contacting geocoder.ca: #{ex.to_s}" }
  end

  def search_osm_namefinder(query)
    results = Array.new

    # ask OSM namefinder
    response = fetch_xml("http://www.frankieandshadow.com/osm/search.xml?find=#{URI.escape(query)}")

    # parse the response
    response.elements.each("searchresults/named") do |named|
      lat = named.attributes["lat"].to_s
      lon = named.attributes["lon"].to_s
      zoom = named.attributes["zoom"].to_s
      place = named.elements["place/named"] || named.elements["nearestplaces/named"]
      type = named.attributes["info"].to_s.capitalize
      name = named.attributes["name"].to_s
      if place
        distance = format_distance(place.attributes["approxdistance"].to_i)
        direction = format_direction(place.attributes["direction"].to_i)
        placename = place.attributes["name"].to_s
        results.push({:lat => lat, :lon => lon, :zoom => zoom,
                      :description => "#{type} #{name}, #{distance} #{direction} of #{placename}"})
      else
        results.push({:lat => lat, :lon => lon, :zoom => zoom,
                      :description => "#{type} #{name}"})
      end
    end

    return { :source => "OpenStreetMap Namefinder", :url => "http://www.frankieandshadow.com/osm/", :results => results }
  rescue Exception => ex
    return { :source => "OpenStreetMap Namefinder", :url => "http://www.frankieandshadow.com/osm/", :error => "Error contacting www.frankieandshadow.com: #{ex.to_s}" }
  end

  def search_geonames(query)
    results = Array.new

    # ask geonames.org
    response = fetch_xml("http://ws.geonames.org/search?q=#{URI.escape(query)}&maxRows=20")

    # parse the response
    response.elements.each("geonames/geoname") do |geoname|
      lat = geoname.get_text("lat").to_s
      lon = geoname.get_text("lng").to_s
      name = geoname.get_text("name").to_s
      country = geoname.get_text("countryName").to_s
      results.push({:lat => lat, :lon => lon, :zoom => 12,
                    :description => "#{name}, #{country}"})
    end

    return { :source => "GeoNames", :url => "http://www.geonames.org/", :results => results }
  rescue Exception => ex
    return { :source => "GeoNames", :url => "http://www.geonames.org/", :error => "Error contacting ws.geonames.org: #{ex.to_s}" }
  end

  def fetch_text(url)
    return Net::HTTP.get(URI.parse(url))
  end

  def fetch_xml(url)
    return REXML::Document.new(fetch_text(url))
  end

  def format_distance(distance)
    return "less than 1km" if distance == 0
    return "about #{distance}km"
  end

  def format_direction(bearing)
    return "south-west" if bearing >= 22.5 and bearing < 67.5
    return "south" if bearing >= 67.5 and bearing < 112.5
    return "south-east" if bearing >= 112.5 and bearing < 157.5
    return "east" if bearing >= 157.5 and bearing < 202.5
    return "north-east" if bearing >= 202.5 and bearing < 247.5
    return "north" if bearing >= 247.5 and bearing < 292.5
    return "north-west" if bearing >= 292.5 and bearing < 337.5
    return "west"
  end
end
