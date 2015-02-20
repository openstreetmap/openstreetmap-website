class BoundingBox
  attr_reader :min_lon, :min_lat, :max_lon, :max_lat

  LON_LIMIT = 180.0
  LAT_LIMIT = 90.0
  SCALED_LON_LIMIT = LON_LIMIT *  GeoRecord::SCALE
  SCALED_LAT_LIMIT = LAT_LIMIT *  GeoRecord::SCALE

  public

  def initialize(min_lon, min_lat, max_lon, max_lat)
    @min_lon = min_lon.to_f unless min_lon.nil?
    @min_lat = min_lat.to_f unless min_lat.nil?
    @max_lon = max_lon.to_f unless max_lon.nil?
    @max_lat = max_lat.to_f unless max_lat.nil?
  end

  def self.from_s(s)
    BoundingBox.new(*s.split(/,/)) if s.count(",") == 3
  end

  def self.from_bbox_params(params)
    if params[:bbox] && params[:bbox].count(",") == 3
      bbox_array = params[:bbox].split(",")
    end
    from_bbox_array(bbox_array)
  end

  def self.from_lon_lat_params(params)
    if params[:minlon] && params[:minlat] && params[:maxlon] && params[:maxlat]
      bbox_array = [params[:minlon], params[:minlat], params[:maxlon], params[:maxlat]]
    end
    from_bbox_array(bbox_array)
  end

  def self.from_lrbt_params(params)
    if params[:l] && params[:b] && params[:t] && params[:t]
      bbox_array = [params[:l], params[:b], params[:r], params[:t]]
    end
    from_bbox_array(bbox_array)
  end

  def expand!(bbox, margin = 0)
    update!(bbox) unless complete?
    # only try to expand the bbox if there is a value for every coordinate
    # which there will be from the previous line as long as array does not contain a nil
    if bbox.complete?
      @min_lon = [-SCALED_LON_LIMIT,
                  bbox.min_lon + margin * (min_lon - max_lon)].max if bbox.min_lon < min_lon
      @min_lat = [-SCALED_LAT_LIMIT,
                  bbox.min_lat + margin * (min_lat - max_lat)].max if bbox.min_lat < min_lat
      @max_lon = [+SCALED_LON_LIMIT,
                  bbox.max_lon + margin * (max_lon - min_lon)].min if bbox.max_lon > max_lon
      @max_lat = [+SCALED_LAT_LIMIT,
                  bbox.max_lat + margin * (max_lat - min_lat)].min if bbox.max_lat > max_lat
    end
    self
  end

  def check_boundaries
    # check the bbox is sane
    if min_lon > max_lon
      fail OSM::APIBadBoundingBox.new(
        "The minimum longitude must be less than the maximum longitude, but it wasn't")
    end
    if min_lat > max_lat
      fail OSM::APIBadBoundingBox.new(
        "The minimum latitude must be less than the maximum latitude, but it wasn't")
    end
    if min_lon < -LON_LIMIT || min_lat < -LAT_LIMIT || max_lon > +LON_LIMIT || max_lat > +LAT_LIMIT
      fail OSM::APIBadBoundingBox.new("The latitudes must be between #{-LAT_LIMIT} and #{LAT_LIMIT}," +
                                       " and longitudes between #{-LON_LIMIT} and #{LON_LIMIT}")
    end
    self
  end

  def check_size(max_area = MAX_REQUEST_AREA)
    # check the bbox isn't too large
    if area > max_area
      fail OSM::APIBadBoundingBox.new("The maximum bbox size is " + max_area.to_s +
        ", and your request was too large. Either request a smaller area, or use planet.osm")
    end
    self
  end

  ##
  # returns area of the bbox as a rough comparative quantity
  def area
    if complete?
      (max_lon - min_lon) * (max_lat - min_lat)
    else
      0
    end
  end

  def complete?
    !to_a.include?(nil)
  end

  def centre_lon
    (min_lon + max_lon) / 2.0
  end

  def centre_lat
    (min_lat + max_lat) / 2.0
  end

  def width
    max_lon - min_lon
  end

  def height
    max_lat - min_lat
  end

  def slippy_width(zoom)
    width * 256.0 * 2.0**zoom / 360.0
  end

  def slippy_height(zoom)
    min = min_lat * Math::PI / 180.0
    max = max_lat * Math::PI / 180.0

    Math.log((Math.tan(max) + 1.0 / Math.cos(max)) /
             (Math.tan(min) + 1.0 / Math.cos(min))) *
      (128.0 * 2.0**zoom / Math::PI)
  end

  # there are two forms used for bounds with and without an underscore,
  # cater for both forms eg minlon and min_lon
  def add_bounds_to(hash, underscore = "")
    hash["min#{underscore}lat"] = min_lat.to_s
    hash["min#{underscore}lon"] = min_lon.to_s
    hash["max#{underscore}lat"] = max_lat.to_s
    hash["max#{underscore}lon"] = max_lon.to_s
    hash
  end

  def to_scaled
    BoundingBox.new((min_lon * GeoRecord::SCALE),
                    (min_lat * GeoRecord::SCALE),
                    (max_lon * GeoRecord::SCALE),
                    (max_lat * GeoRecord::SCALE))
  end

  def to_unscaled
    BoundingBox.new((min_lon / GeoRecord::SCALE),
                    (min_lat / GeoRecord::SCALE),
                    (max_lon / GeoRecord::SCALE),
                    (max_lat / GeoRecord::SCALE))
  end

  def to_a
    [min_lon, min_lat, max_lon, max_lat]
  end

  def to_s
    "#{min_lon},#{min_lat},#{max_lon},#{max_lat}"
  end

  private

  def self.from_bbox_array(bbox_array)
    unless bbox_array
      fail OSM::APIBadUserInput.new(
        "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat")
    end
    # Take an array of length 4, create a bounding box with min_lon, min_lat, max_lon and
    # max_lat within their respective boundaries.
    min_lon = [[bbox_array[0].to_f, -LON_LIMIT].max, +LON_LIMIT].min
    min_lat = [[bbox_array[1].to_f, -LAT_LIMIT].max, +LAT_LIMIT].min
    max_lon = [[bbox_array[2].to_f, +LON_LIMIT].min, -LON_LIMIT].max
    max_lat = [[bbox_array[3].to_f, +LAT_LIMIT].min, -LAT_LIMIT].max
    BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end

  def update!(bbox)
    # ensure that bbox has no nils in it. if there are any
    # nils, just use the bounding box update to write over them.
    @min_lon = bbox.min_lon if min_lon.nil?
    @min_lat = bbox.min_lat if min_lat.nil?
    @max_lon = bbox.max_lon if max_lon.nil?
    @max_lat = bbox.max_lat if max_lat.nil?
  end
end
