class AddMoreControlsToGpxFiles < ActiveRecord::Migration[4.2]
  class Trace < ApplicationRecord
    self.table_name = "gpx_files"
  end

  def self.up
    create_enum :gpx_visibility_enum, %w[private public trackable identifiable]
    add_column :gpx_files, :visibility, :gpx_visibility_enum, :default => "public", :null => false
    Trace.where(:public => false).update_all(:visibility => "private")
    add_index :gpx_files, [:visible, :visibility], :name => "gpx_files_visible_visibility_idx"
    remove_index :gpx_files, :name => "gpx_files_visible_public_idx"
    remove_column :gpx_files, :public
  end

  def self.down
    add_column :gpx_files, :public, :boolean, :default => true, :null => false
    Trace.where(:visibility => "private").update_all(:public => false)
    add_index :gpx_files, [:visible, :public], :name => "gpx_files_visible_public_idx"
    remove_index :gpx_files, :name => "gpx_files_visible_visibility_idx"
    remove_column :gpx_files, :visibility
    drop_enumeration :gpx_visibility_enum
  end
end
