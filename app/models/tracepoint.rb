class Tracepoint < ActiveRecord::Base
  include GeoRecord

  self.table_name = "gps_points"

  validates_numericality_of :trackid, :only_integer => true
  validates_numericality_of :latitude, :only_integer => true
  validates_numericality_of :longitude, :only_integer => true
  validates_associated :trace
  validates_presence_of :timestamp

  belongs_to :trace, :foreign_key => 'gpx_id'

  def to_xml_node(print_timestamp = false)
    el1 = XML::Node.new 'trkpt'
    el1['lat'] = self.lat.to_s
    el1['lon'] = self.lon.to_s
    el1 << (XML::Node.new("time") << self.timestamp.xmlschema) if print_timestamp
    return el1
  end
end
