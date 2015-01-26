require 'migrate'

class AddForeignKeys < ActiveRecord::Migration
  def self.up
    add_foreign_key :changeset_tags, :changesets, :column => :id, :name => "changeset_tags_id_fkey"
    add_foreign_key :diary_comments, :diary_entries, :name => "diary_comments_diary_entry_id_fkey"
    add_foreign_key :gps_points, :gpx_files, :column => :gpx_id, :name => "gps_points_gpx_id_fkey"
    add_foreign_key :gpx_file_tags, :gpx_files, :column => :gpx_id, :name => "gpx_file_tags_gpx_id_fkey"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
