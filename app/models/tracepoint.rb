class Tracepoint < ActiveRecord::Base
  set_table_name 'gps_points'

#  validates_numericality_of :latitude
#  validates_numericality_of :longitude

  belongs_to :user
  belongs_to :trace, :foreign_key => 'gpx_id'
 
  def self.find_by_area(minlat, minlon, maxlat, maxlon, options)
    self.with_scope(:find => {:conditions => OSM.sql_for_area(minlat, minlon, maxlat, maxlon)}) do
      return self.find(:all, options)
    end
  end

  def lat=(l)
    self.latitude = l * 1000000
  end

  def lng=(l)
    self.longitude = l * 1000000
  end

  def lat
    return self.latitude.to_f / 1000000
  end

  def lon
    return self.longitude.to_f / 1000000
  end

  def to_xml_node
    el1 = XML::Node.new 'trkpt'
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    return el1
  end
end
