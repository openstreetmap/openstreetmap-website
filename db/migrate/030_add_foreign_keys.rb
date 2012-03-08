require 'migrate'

class AddForeignKeys < ActiveRecord::Migration
  def self.up
    add_foreign_key :changeset_tags, [:id], :changesets
    add_foreign_key :diary_comments, [:diary_entry_id], :diary_entries, [:id]
    add_foreign_key :gps_points, [:gpx_id], :gpx_files, [:id]
    add_foreign_key :gpx_file_tags, [:gpx_id], :gpx_files, [:id]
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
