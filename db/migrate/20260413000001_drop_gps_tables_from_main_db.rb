# frozen_string_literal: true

# Drop the GPS tables (gps_points, gpx_file_tags, gpx_files) from the main database.
# These tables now live in a separate GPS database (see GpsRecord model).
class DropGpsTablesFromMainDb < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :gps_points, :gpx_files, :column => :gpx_id
    remove_foreign_key :gpx_file_tags, :gpx_files, :column => :gpx_id
    remove_foreign_key :gpx_files, :users, :column => :user_id
    drop_table :gps_points
    drop_table :gpx_file_tags
    drop_table :gpx_files
    safety_assured { execute "DROP TYPE IF EXISTS gpx_visibility_enum" }
  end
end
