# frozen_string_literal: true

class CreateGpsTables < ActiveRecord::Migration[8.1]
  def change
    create_table :gpx_files, id: :bigint do |t|
      t.bigint :user_id, null: false
      t.boolean :visible, default: true, null: false
      t.string :name, default: "", null: false
      t.bigint :size
      t.float :latitude
      t.float :longitude
      t.datetime :timestamp, null: false
      t.string :description, default: "", null: false
      t.boolean :inserted, null: false
      t.column :visibility, :string, default: "public", null: false
    end

    add_index :gpx_files, :timestamp, name: "gpx_files_timestamp_idx"
    add_index :gpx_files, [:visible, :visibility], name: "gpx_files_visible_visibility_idx"
    add_index :gpx_files, [:user_id, :id], name: "index_gpx_files_on_user_id_and_id"

    create_table :gpx_file_tags, id: :bigint do |t|
      t.bigint :gpx_id, null: false
      t.string :tag, null: false
    end

    add_index :gpx_file_tags, :gpx_id, name: "gpx_file_tags_gpxid_idx"
    add_index :gpx_file_tags, :tag, name: "gpx_file_tags_tag_idx"

    create_table :gps_points, id: false do |t|
      t.float :altitude
      t.integer :trackid, null: false
      t.integer :latitude, null: false
      t.integer :longitude, null: false
      t.bigint :gpx_id, null: false
      t.datetime :timestamp
      t.bigint :tile
    end

    add_index :gps_points, :gpx_id, name: "points_gpxid_idx"
    add_index :gps_points, :tile, name: "points_tile_idx"
  end
end
