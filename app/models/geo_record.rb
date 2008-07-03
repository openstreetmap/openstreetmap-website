class GeoRecord < ActiveRecord::Base
  before_save :update_tile

  # This is a scaling factor for going between the lat and lon via the API
  # and the longitude and latitude that is stored in the database
  SCALE = 10000000

  # Is this node within -90 <= latitude <= 90 and -180 <= longitude <= 180
  # * returns true/false
  def in_world?
    return false if self.lat < -90 or self.lat > 90
    return false if self.lon < -180 or self.lon > 180
    return true
  end

  def self.find_by_area(minlat, minlon, maxlat, maxlon, options)
    self.with_scope(:find => {:conditions => OSM.sql_for_area(minlat, minlon, maxlat, maxlon)}) do
      return self.find(:all, options)
    end
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
    return self.latitude.to_f / SCALE
  end

  # Return WGS84 longitude
  def lon
    return self.longitude.to_f / SCALE
  end

  # Potlatch projections
  def lon_potlatch(baselong,masterscale)
    (self.lon-baselong)*masterscale
  end

  def lat_potlatch(basey,masterscale)
    -(lat2y(self.lat)-basey)*masterscale
  end
  
  private
  
  def lat2y(a)
    180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
  end

end

