module GeoRecord
  extend ActiveSupport::Concern

  # Ensure that when coordinates are printed that they are always in decimal degrees,
  # and not e.g. 4.0e-05
  # Unfortunately you can't extend Numeric classes directly (e.g. `Coord < Float`).
  class Coord < DelegateClass(Float)
    def initialize(obj)
      super(obj)
    end

    def to_s
      format("%.7f", self)
    end
  end

  # This scaling factor is used to convert between the float lat/lon that is
  # returned by the API, and the integer lat/lon equivalent that is stored in
  # the database.
  SCALE = 10000000

  included do
    scope :bbox, ->(bbox) { where(OSM.sql_for_area(bbox, "#{table_name}.")) }
    before_save :update_tile
  end

  # Is this node within -90 >= latitude >= 90 and -180 >= longitude >= 180
  # * returns true/false
  def in_world?
    return false if lat < -90 || lat > 90
    return false if lon < -180 || lon > 180

    true
  end

  def update_tile
    self.tile = QuadTile.tile_for_point(lat, lon)
  end

  def lat=(l)
    self.latitude = (l * SCALE).round
  end

  def lon=(l)
    self.longitude = (l * SCALE).round
  end

  # Return WGS84 latitude
  def lat
    Coord.new(latitude.to_f / SCALE)
  end

  # Return WGS84 longitude
  def lon
    Coord.new(longitude.to_f / SCALE)
  end
end
