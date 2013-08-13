# The OSM module provides support functions for OSM.
module OSM

  require 'time'
  require 'rexml/parsers/sax2parser'
  require 'rexml/text'
  require 'xml/libxml'

  if defined?(SystemTimer)
    Timer = SystemTimer
  else
    require 'timeout'
    Timer = Timeout
  end

  # The base class for API Errors.
  class APIError < RuntimeError
    def status
      :internal_server_error
    end

    def to_s
      "Generic API Error"
    end
  end

  # Raised when an API object is not found.
  class APINotFoundError < APIError
    def status
      :not_found
    end

    def to_s
      "Object not found"
    end
  end

  # Raised when a precondition to an API action fails sanity check.
  class APIPreconditionFailedError < APIError
    def initialize(message = "")
      @message = message
    end

    def status
      :precondition_failed
    end

    def to_s
      "Precondition failed: #{@message}"
    end
  end

  # Raised when to delete an already-deleted object.
  class APIAlreadyDeletedError < APIError
    def initialize(object = "object", object_id = "")
      @object, @object_id = object, object_id
    end

    attr_reader :object, :object_id

    def status
      :gone
    end

    def to_s
      "The #{object} with the id #{object_id} has already been deleted"
    end
  end

  # Raised when the user logged in isn't the same as the changeset
  class APIUserChangesetMismatchError < APIError
    def status
      :conflict
    end

    def to_s
      "The user doesn't own that changeset"
    end
  end

  # Raised when the changeset provided is already closed
  class APIChangesetAlreadyClosedError < APIError
    def initialize(changeset)
      @changeset = changeset
    end

    attr_reader :changeset

    def status
      :conflict
    end

    def to_s
      "The changeset #{@changeset.id} was closed at #{@changeset.closed_at}"
    end
  end

  # Raised when a change is expecting a changeset, but the changeset doesn't exist
  class APIChangesetMissingError < APIError
    def status
      :conflict
    end

    def to_s
      "You need to supply a changeset to be able to make a change"
    end
  end

  # Raised when a diff is uploaded containing many changeset IDs which don't match
  # the changeset ID that the diff was uploaded to.
  class APIChangesetMismatchError < APIError
    def initialize(provided, allowed)
      @provided, @allowed = provided, allowed
    end

    def status
      :conflict
    end

    def to_s
      "Changeset mismatch: Provided #{@provided} but only #{@allowed} is allowed"
    end
  end

  # Raised when a diff upload has an unknown action. You can only have create,
  # modify, or delete
  class APIChangesetActionInvalid < APIError
    def initialize(provided)
      @provided = provided
    end

    def status
      :bad_request
    end

    def to_s
      "Unknown action #{@provided}, choices are create, modify, delete"
    end
  end

  # Raised when bad XML is encountered which stops things parsing as
  # they should.
  class APIBadXMLError < APIError
    def initialize(model, xml, message="")
      @model, @xml, @message = model, xml, message
    end

    def status
      :bad_request
    end

    def to_s
      "Cannot parse valid #{@model} from xml string #{@xml}. #{@message}"
    end
  end

  # Raised when the provided version is not equal to the latest in the db.
  class APIVersionMismatchError < APIError
    def initialize(id, type, provided, latest)
      @id, @type, @provided, @latest = id, type, provided, latest
    end

    attr_reader :provided, :latest, :id, :type

    def status
      :conflict
    end

    def to_s
      "Version mismatch: Provided #{provided}, server had: #{latest} of #{type} #{id}"
    end
  end

  # raised when a two tags have a duplicate key string in an element.
  # this is now forbidden by the API.
  class APIDuplicateTagsError < APIError
    def initialize(type, id, tag_key)
      @type, @id, @tag_key = type, id, tag_key
    end

    attr_reader :type, :id, :tag_key

    def status
      :bad_request
    end

    def to_s
      "Element #{@type}/#{@id} has duplicate tags with key #{@tag_key}"
    end
  end

  # Raised when a way has more than the configured number of way nodes.
  # This prevents ways from being to long and difficult to work with
  class APITooManyWayNodesError < APIError
    def initialize(id, provided, max)
      @id, @provided, @max = id, provided, max
    end

    attr_reader :id, :provided, :max

    def status
      :bad_request
    end

    def to_s
      "You tried to add #{provided} nodes to way #{id}, however only #{max} are allowed"
    end
  end

  ##
  # raised when user input couldn't be parsed
  class APIBadUserInput < APIError
    def initialize(message)
      @message = message
    end

    def status
      :bad_request
    end

    def to_s
      @message
    end
  end

  ##
  # raised when bounding box is invalid
  class APIBadBoundingBox < APIError
    def initialize(message)
      @message = message
    end

    def status
      :bad_request
    end

    def to_s
      @message
    end
  end

  ##
  # raised when an API call is made using a method not supported on that URI
  class APIBadMethodError < APIError
    def initialize(supported_method)
      @supported_method = supported_method
    end

    def status
      :method_not_allowed
    end

    def to_s
      "Only method #{@supported_method} is supported on this URI"
    end
  end

  ##
  # raised when an API call takes too long
  class APITimeoutError < APIError
    def status
      :request_timeout
    end

    def to_s
      "Request timed out"
    end
  end

  ##
  # raised when someone tries to redact a current version of
  # an element - only historical versions can be redacted.
  class APICannotRedactError < APIError
    def status
      :bad_request
    end

    def to_s
      "Cannot redact current version of element, only historical versions may be redacted."
    end
  end

  # Raised when the note provided is already closed
  class APINoteAlreadyClosedError < APIError
    def initialize(note)
      @note = note
    end

    attr_reader :note

    def status
      :conflict
    end

    def to_s
      "The note #{@note.id} was closed at #{@note.closed_at}"
    end
  end

  # Raised when the note provided is already open
  class APINoteAlreadyOpenError < APIError
    def initialize(note)
      @note = note
    end

    attr_reader :note

    def status
      :conflict
    end

    def to_s
      "The note #{@note.id} is already open"
    end
  end

  # raised when a two preferences have a duplicate key string.
  class APIDuplicatePreferenceError < APIError
    def initialize(key)
      @key = key
    end

    attr_reader :key

    def status
      :bad_request
    end

    def to_s
      "Duplicate preferences with key #{@key}"
    end
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

      begin
        lonradius = 2 * asin(sqrt(sin(radius / 6372.795 / 2) ** 2 / cos(@lat) ** 2))
      rescue Errno::EDOM
        lonradius = PI
      end

      minlat = (@lat - latradius) * 180 / PI
      maxlat = (@lat + latradius) * 180 / PI
      minlon = (@lon - lonradius) * 180 / PI
      maxlon = (@lon + lonradius) * 180 / PI

      return { :minlat => minlat, :maxlat => maxlat, :minlon => minlon, :maxlon => maxlon }
    end

    # get the SQL to use to calculate distance
    def sql_for_distance(lat_field, lon_field)
      "6372.795 * 2 * asin(sqrt(power(sin((radians(#{lat_field}) - #{@lat}) / 2), 2) + cos(#{@lat}) * cos(radians(#{lat_field})) * power(sin((radians(#{lon_field}) - #{@lon})/2), 2)))"
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
      root['version'] = API_VERSION.to_s
      root['generator'] = GENERATOR
      root['copyright'] = COPYRIGHT_OWNER
      root['attribution'] = ATTRIBUTION_URL
      root['license'] =  LICENSE_URL
      doc.root = root
      return doc
    end
  end

  def self.IPToCountry(ip_address)
    Timer.timeout(4) do
      ipinfo = Quova::IpInfo.new(ip_address)

      if ipinfo.status == Quova::Success then
        country = ipinfo.country_code
      else
        Net::HTTP.start('api.hostip.info') do |http|
          country = http.get("/country.php?ip=#{ip_address}").body
          country = "GB" if country == "UK"
        end
      end

      return country.upcase
    end

    return nil
  rescue Exception
    return nil
  end

  def self.IPLocation(ip_address)
    code = OSM.IPToCountry(ip_address)

    if code and country = Country.find_by_code(code)
      return { :minlon => country.min_lon, :minlat => country.min_lat, :maxlon => country.max_lon, :maxlat => country.max_lat }
    end

    return nil
  end

  # Parse a float, raising a specified exception on failure
  def self.parse_float(str, klass, *args)
    Float(str)
  rescue
    raise klass.new(*args)
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

  # Return an SQL fragment to select a given area of the globe
  def self.sql_for_area(bbox, prefix = nil)
    tilesql = QuadTile.sql_for_area(bbox, prefix)
    bbox = bbox.to_scaled

    return "#{tilesql} AND #{prefix}latitude BETWEEN #{bbox.min_lat} AND #{bbox.max_lat} " +
                      "AND #{prefix}longitude BETWEEN #{bbox.min_lon} AND #{bbox.max_lon}"
  end

  def self.legal_text_for_country(country_code)
    file_name = File.join(Rails.root, "config", "legales", country_code.to_s + ".yml")
    file_name = File.join(Rails.root, "config", "legales", DEFAULT_LEGALE + ".yml") unless File.exist? file_name
    YAML::load_file(file_name)
  end
end
