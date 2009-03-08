# The OSM module provides support functions for OSM.
module OSM

  require 'time'
  require 'rexml/parsers/sax2parser'
  require 'rexml/text'
  require 'xml/libxml'
  require 'digest/md5'
  require 'RMagick'

  # The base class for API Errors.
  class APIError < RuntimeError
  end

  # Raised when an API object is not found.
  class APINotFoundError < APIError
  end

  # Raised when a precondition to an API action fails sanity check.
  class APIPreconditionFailedError < APIError
  end

  # Raised when to delete an already-deleted object.
  class APIAlreadyDeletedError < APIError
  end

  # Helper methods for going to/from mercator and lat/lng.
  class Mercator
    include Math

    #init me with your bounding box and the size of your image
    def initialize(min_lat, min_lon, max_lat, max_lon, width, height)
      xsize = xsheet(max_lon) - xsheet(min_lon)
      ysize = ysheet(max_lat) - ysheet(min_lat)
      xscale = xsize / width
      yscale = ysize / height
      scale = [xscale, yscale].max

      xpad = width * scale - xsize
      ypad = height * scale - ysize

      @width = width
      @height = height

      @tx = xsheet(min_lon) - xpad / 2
      @ty = ysheet(min_lat) - ypad / 2

      @bx = xsheet(max_lon) + xpad / 2
      @by = ysheet(max_lat) + ypad / 2
    end

    #the following two functions will give you the x/y on the entire sheet

    def ysheet(lat)
      log(tan(PI / 4 + (lat * PI / 180 / 2))) / (PI / 180)
    end

    def xsheet(lon)
      lon
    end

    #and these two will give you the right points on your image. all the constants can be reduced to speed things up. FIXME

    def y(lat)
      return @height - ((ysheet(lat) - @ty) / (@by - @ty) * @height)
    end

    def x(lon)
      return  ((xsheet(lon) - @tx) / (@bx - @tx) * @width)
    end
  end

  class GreatCircle
    include Math

    # initialise with a base position
    def initialize(lat, lon)
      @lat = lat * PI / 180
      @lon = lon * PI / 180
    end

    # get the distance from the base position to a given position
    def distance(lat, lon)
      lat = lat * PI / 180
      lon = lon * PI / 180
      return 6372.795 * 2 * asin(sqrt(sin((lat - @lat) / 2) ** 2 + cos(@lat) * cos(lat) * sin((lon - @lon)/2) ** 2))
    end

    # get the worst case bounds for a given radius from the base position
    def bounds(radius)
      latradius = 2 * asin(sqrt(sin(radius / 6372.795 / 2) ** 2))
      lonradius = 2 * asin(sqrt(sin(radius / 6372.795 / 2) ** 2 / cos(@lat) ** 2))
      minlat = (@lat - latradius) * 180 / PI
      maxlat = (@lat + latradius) * 180 / PI
      minlon = (@lon - lonradius) * 180 / PI
      maxlon = (@lon + lonradius) * 180 / PI
      return { :minlat => minlat, :maxlat => maxlat, :minlon => minlon, :maxlon => maxlon }
    end
  end

  class GeoRSS
    def initialize(feed_title='OpenStreetMap GPS Traces', feed_description='OpenStreetMap GPS Traces', feed_url='http://www.openstreetmap.org/traces/')
      @doc = XML::Document.new
      @doc.encoding = XML::Encoding::UTF_8

      rss = XML::Node.new 'rss'
      @doc.root = rss
      rss['version'] = "2.0"
      rss['xmlns:geo'] = "http://www.w3.org/2003/01/geo/wgs84_pos#"
      @channel = XML::Node.new 'channel'
      rss << @channel
      title = XML::Node.new 'title'
      title <<  feed_title
      @channel << title
      description_el = XML::Node.new 'description'
      @channel << description_el

      description_el << feed_description
      link = XML::Node.new 'link'
      link << feed_url
      @channel << link
      image = XML::Node.new 'image'
      @channel << image
      url = XML::Node.new 'url'
      url << 'http://www.openstreetmap.org/images/mag_map-rss2.0.png'
      image << url
      title = XML::Node.new 'title'
      title << "OpenStreetMap"
      image << title
      width = XML::Node.new 'width'
      width << '100'
      image << width
      height = XML::Node.new 'height'
      height << '100'
      image << height
      link = XML::Node.new 'link'
      link << feed_url
      image << link
    end

    def add(latitude=0, longitude=0, title_text='dummy title', author_text='anonymous', url='http://www.example.com/', description_text='dummy description', timestamp=DateTime.now)
      item = XML::Node.new 'item'

      title = XML::Node.new 'title'
      item << title
      title << title_text
      link = XML::Node.new 'link'
      link << url
      item << link

      guid = XML::Node.new 'guid'
      guid << url
      item << guid

      description = XML::Node.new 'description'
      description << description_text
      item << description

      author = XML::Node.new 'author'
      author << author_text
      item << author

      pubDate = XML::Node.new 'pubDate'
      pubDate << timestamp.to_s(:rfc822)
      item << pubDate

      if latitude
        lat_el = XML::Node.new 'geo:lat'
        lat_el << latitude.to_s
        item << lat_el
      end

      if longitude
        lon_el = XML::Node.new 'geo:long'
        lon_el << longitude.to_s
        item << lon_el
      end

      @channel << item
    end

    def to_s
      return @doc.to_s
    end
  end

  class API
    def get_xml_doc
      doc = XML::Document.new
      doc.encoding = XML::Encoding::UTF_8
      root = XML::Node.new 'osm'
      root['version'] = API_VERSION
      root['generator'] = 'OpenStreetMap server'
      doc.root = root
      return doc
    end
  end

  def self.IPLocation(ip_address)
    Timeout::timeout(4) do
      Net::HTTP.start('api.hostip.info') do |http|
        country = http.get("/country.php?ip=#{ip_address}").body
        country = "GB" if country == "UK"
        Net::HTTP.start('ws.geonames.org') do |http|
          xml = REXML::Document.new(http.get("/countryInfo?country=#{country}").body)
          xml.elements.each("geonames/country") do |ele|
            minlon = ele.get_text("bBoxWest").to_s
            minlat = ele.get_text("bBoxSouth").to_s
            maxlon = ele.get_text("bBoxEast").to_s
            maxlat = ele.get_text("bBoxNorth").to_s
            return { :minlon => minlon, :minlat => minlat, :maxlon => maxlon, :maxlat => maxlat }
          end
        end
      end
    end

    return nil
  rescue Exception
    return nil
  end

  # Construct a random token of a given length
  def self.make_token(length = 30)
    chars = 'abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    token = ''

    length.times do
      token += chars[(rand * chars.length).to_i].chr
    end

    return token
  end

  # Return an encrypted version of a password
  def self.encrypt_password(password, salt)
    return Digest::MD5.hexdigest(password) if salt.nil?
    return Digest::MD5.hexdigest(salt + password)
  end

  # Return an SQL fragment to select a given area of the globe
  def self.sql_for_area(minlat, minlon, maxlat, maxlon, prefix = nil)
    tilesql = QuadTile.sql_for_area(minlat, minlon, maxlat, maxlon, prefix)
    minlat = (minlat * 10000000).round
    minlon = (minlon * 10000000).round
    maxlat = (maxlat * 10000000).round
    maxlon = (maxlon * 10000000).round

    return "#{tilesql} AND #{prefix}latitude BETWEEN #{minlat} AND #{maxlat} AND #{prefix}longitude BETWEEN #{minlon} AND #{maxlon}"
  end


end
