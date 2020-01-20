# == Schema Information
#
# Table name: gps_points
#
#  altitude  :float
#  trackid   :integer          not null
#  latitude  :integer          not null
#  longitude :integer          not null
#  gpx_id    :bigint(8)        not null
#  timestamp :datetime
#  tile      :bigint(8)
#
# Indexes
#
#  points_gpxid_idx  (gpx_id)
#  points_tile_idx   (tile)
#
# Foreign Keys
#
#  gps_points_gpx_id_fkey  (gpx_id => gpx_files.id)
#

class Tracepoint < ApplicationRecord
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
