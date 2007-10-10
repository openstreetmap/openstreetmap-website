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

  def lat
    return self.latitude.to_f / 10000000
  end

  def lon
    return self.longitude.to_f / 10000000
  end
end
