class Tracepoint < ActiveRecord::Base
  include GeoRecord

  self.table_name = "gps_points"

  validates :trackid, :numericality => { :only_integer => true }
  validates :latitude, :longitude, :numericality => { :only_integer => true }
  validates :trace, :associated => true
  validates :timestamp, :presence => true

  belongs_to :trace, :foreign_key => "gpx_id"

  def to_xml_node(print_timestamp = false)
    el1 = XML::Node.new "trkpt"
    el1["lat"] = lat.to_s
    el1["lon"] = lon.to_s
    el1 << (XML::Node.new("time") << timestamp.xmlschema) if print_timestamp
    el1
  end
end
