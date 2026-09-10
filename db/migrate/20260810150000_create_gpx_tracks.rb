# frozen_string_literal: true

class CreateGpxTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :gpx_tracks, :primary_key => [:gpx_id, :trackid, :segment] do |t|
      t.bigint :gpx_id, :null => false
      t.integer :trackid, :null => false
      t.integer :segment, :null => false
      t.column :geom, "geometry(GeometryZM,4326)", :null => false

      t.check_constraint "ST_GeometryType(geom) IN ('ST_LineString', 'ST_Point')",
                         :name => "gpx_tracks_geom_line_or_point"
      t.index :geom, :using => :gist
      t.foreign_key :gpx_files, :column => :gpx_id
    end
  end
end
