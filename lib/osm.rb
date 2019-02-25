# The OSM module provides support functions for OSM.
module OSM
  require "time"
  require "rexml/parsers/sax2parser"
  require "rexml/text"
  require "xml/libxml"

  if defined?(SystemTimer)
    Timer = SystemTimer
  else
    require "timeout"
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

  # Raised when access is denied.
  class APIAccessDenied < RuntimeError
    def status
      :forbidden
    end

    def to_s
      "Access denied"
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
      @object = object
      @object_id = object_id
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

  # Raised when the changeset provided is not yet closed
  class APIChangesetNotYetClosedError < APIError
    def initialize(changeset)
      @changeset = changeset
    end

    attr_reader :changeset

    def status
      :conflict
    end

    def to_s
      "The changeset #{@changeset.id} is not yet closed."
    end
  end

  # Raised when a user is already subscribed to the changeset
  class APIChangesetAlreadySubscribedError < APIError
    def initialize(changeset)
      @changeset = changeset
    end

    attr_reader :changeset

    def status
      :conflict
    end

    def to_s
      "You are already subscribed to changeset #{@changeset.id}."
    end
  end

  # Raised when a user is not subscribed to the changeset
  class APIChangesetNotSubscribedError < APIError
    def initialize(changeset)
      @changeset = changeset
    end

    attr_reader :changeset

    def status
      :not_found
    end

    def to_s
      "You are not subscribed to changeset #{@changeset.id}."
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
      @provided = provided
      @allowed = allowed
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
    def initialize(model, xml, message = "")
      @model = model
      @xml = xml
      @message = message
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
      @id = id
      @type = type
      @provided = provided
      @latest = latest
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
      @type = type
      @id = id
      @tag_key = tag_key
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
      @id = id
      @provided = provided
      @max = max
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

    # init me with your bounding box and the size of your image
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

    # the following two functions will give you the x/y on the entire sheet

    def ysheet(lat)
      log(tan(PI / 4 + (lat * PI / 180 / 2))) / (PI / 180)
    end

    def xsheet(lon)
      lon
    end

    # and these two will give you the right points on your image. all the constants can be reduced to speed things up. FIXME

    def y(lat)
      @height - ((ysheet(lat) - @ty) / (@by - @ty) * @height)
    end

    def x(lon)
      ((xsheet(lon) - @tx) / (@bx - @tx) * @width)
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
      6372.795 * 2 * asin(sqrt(sin((lat - @lat) / 2)**2 + cos(@lat) * cos(lat) * sin((lon - @lon) / 2)**2))
    end

    # get the worst case bounds for a given radius from the base position
    def bounds(radius)
      latradius = 2 * asin(sqrt(sin(radius / 6372.795 / 2)**2))

      begin
        lonradius = 2 * asin(sqrt(sin(radius / 6372.795 / 2)**2 / cos(@lat)**2))
      rescue Errno::EDOM, Math::DomainError
        lonradius = PI
      end

      minlat = [(@lat - latradius) * 180 / PI, -90].max
      maxlat = [(@lat + latradius) * 180 / PI, 90].min
      minlon = [(@lon - lonradius) * 180 / PI, -180].max
      maxlon = [(@lon + lonradius) * 180 / PI, 180].min

      BoundingBox.new(minlon, minlat, maxlon, maxlat)
    end

    # get the SQL to use to calculate distance
    def sql_for_distance(lat_field, lon_field)
      "6372.795 * 2 * asin(sqrt(power(sin((radians(#{lat_field}) - #{@lat}) / 2), 2) + cos(#{@lat}) * cos(radians(#{lat_field})) * power(sin((radians(#{lon_field}) - #{@lon})/2), 2)))"
    end
  end

  class API
    def get_xml_doc
      doc = XML::Document.new
      doc.encoding = XML::Encoding::UTF_8
      root = XML::Node.new "osm"
      xml_root_attributes.each do |k, v|
        root[k] = v
      end
      doc.root = root
      doc
    end

    def get_xml_credentials_doc
      doc = XML::Document.new
      doc.encoding = XML::Encoding::UTF_8
      root = XML::Node.new "osm"
      root["version"] = API_VERSION.to_s
      root["generator"] = GENERATOR
      doc.root = root
      doc
    end

    def xml_root_attributes
      { "version" => API_VERSION.to_s,
        "generator" => GENERATOR,
        "copyright" => COPYRIGHT_OWNER,
        "attribution" => ATTRIBUTION_URL,
        "license" => LICENSE_URL }
    end
  end

  def self.ip_to_country(ip_address)
    ipinfo = geoip_database.country(ip_address) if defined?(GEOIP_DATABASE)

    if ipinfo
      country = ipinfo.country_code2
    else
      country = http_client.get("https://api.hostip.info/country.php?ip=#{ip_address}").body
      country = "GB" if country == "UK"
    end

    country
  rescue StandardError
    nil
  end

  def self.ip_location(ip_address)
    code = OSM.ip_to_country(ip_address)

    if code && country = Country.find(code)
      return { :minlon => country.min_lon, :minlat => country.min_lat, :maxlon => country.max_lon, :maxlat => country.max_lat }
    end

    nil
  end

  # Parse a float, raising a specified exception on failure
  def self.parse_float(str, klass, *args)
    Float(str)
  rescue StandardError
    raise klass.new(*args)
  end

  # Construct a random token of a given length
  def self.make_token(length = 30)
    chars = "abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    token = ""

    length.times do
      token += chars[(rand * chars.length).to_i].chr
    end

    token
  end

  # Return an SQL fragment to select a given area of the globe
  def self.sql_for_area(bbox, prefix = nil)
    tilesql = QuadTile.sql_for_area(bbox, prefix)
    bbox = bbox.to_scaled

    "#{tilesql} AND #{prefix}latitude BETWEEN #{bbox.min_lat} AND #{bbox.max_lat} " \
      "AND #{prefix}longitude BETWEEN #{bbox.min_lon} AND #{bbox.max_lon}"
  end

  # Return the terms and conditions text for a given country
  def self.legal_text_for_country(country_code)
    file_name = Rails.root.join("config", "legales", country_code.to_s + ".yml")
    file_name = Rails.root.join("config", "legales", DEFAULT_LEGALE + ".yml") unless File.exist? file_name
    YAML.load_file(file_name)
  end

  # Return the HTTP client to use
  def self.http_client
    @http_client ||= Faraday.new
  end

  # Return the GeoIP database handle
  def self.geoip_database
    @geoip_database ||= GeoIP.new(GEOIP_DATABASE) if defined?(GEOIP_DATABASE)
  end
end
