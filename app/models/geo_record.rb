class GeoRecord < ActiveRecord::Base
  before_save :update_tile

  def self.find_by_area(minlat, minlon, maxlat, maxlon, options)
    self.with_scope(:find => {:conditions => OSM.sql_for_area(minlat, minlon, maxlat, maxlon)}) do
      return self.find(:all, options)
    end
  end

  def update_tile
    self.tile = QuadTile.tile_for_point(lat, lon)
  end

  def lat=(l)
    self.latitude = (l * 10000000).round
  end

  def lon=(l)
    self.longitude = (l * 10000000).round
  end

  # Return WGS84 latitude
  def lat
    return self.latitude.to_f / 10000000
  end

  # Return WGS84 longitude
  def lon
    return self.longitude.to_f / 10000000
  end

  # fuck knows
  def lon_potlatch(baselong,masterscale)
    (self.lon-baselong)*masterscale+350
  end

  def lat_potlatch(basey,masterscale)
    -(lat2y(self.lat)-basey)*masterscale+250
  end
  
  private
  
  def lat2y(a)
    180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
  end

end

