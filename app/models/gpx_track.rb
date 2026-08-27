# frozen_string_literal: true

# == Schema Information
#
# Table name: gpx_tracks
#
#  gpx_id  :bigint           not null, primary key
#  trackid :integer          not null, primary key
#  segment :integer          not null, primary key
#  geom    :st_geometry      not null, geometry, 4326
#
# Indexes
#
#  index_gpx_tracks_on_geom  (geom) USING gist
#
# Foreign Keys
#
#  fk_rails_...  (gpx_id => gpx_files.id)
#

class GpxTrack < ApplicationRecord
  validates :trackid, :segment, :geom, :presence => true

  belongs_to :trace, :foreign_key => "gpx_id", :inverse_of => :gpx_tracks
end
