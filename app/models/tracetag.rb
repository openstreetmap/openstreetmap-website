# == Schema Information
#
# Table name: gpx_file_tags
#
#  gpx_id :bigint(8)        default(0), not null
#  tag    :string           not null
#  id     :bigint(8)        not null, primary key
#
# Indexes
#
#  gpx_file_tags_gpxid_idx  (gpx_id)
#  gpx_file_tags_tag_idx    (tag)
#
# Foreign Keys
#
#  gpx_file_tags_gpx_id_fkey  (gpx_id => gpx_files.id)
#

class Tracetag < ApplicationRecord
  self.table_name = "gpx_file_tags"

  belongs_to :trace, :foreign_key => "gpx_id"

  validates :trace, :associated => true
  validates :tag, :length => 1..255, :characters => { :url_safe => true }
end
