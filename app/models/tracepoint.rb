class Tracepoint < GeoRecord
  set_table_name 'gps_points'

  validates_numericality_of :trackid, :only_integer => true
  validates_numericality_of :latitude, :only_integer => true
  validates_numericality_of :longitude, :only_integer => true
  validates_associated :trace
  validates_presence_of :timestamp

  belongs_to :trace, :foreign_key => 'gpx_id'

  def to_xml_node
    el1 = XML::Node.new 'trkpt'
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    return el1
  end
end
