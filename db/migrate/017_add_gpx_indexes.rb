class AddGpxIndexes < ActiveRecord::Migration[4.2]
  def self.up
    add_index "gpx_files", ["user_id"], :name => "gpx_files_user_id_idx"
    add_index "gpx_file_tags", ["tag"], :name => "gpx_file_tags_tag_idx"
  end

  def self.down
    remove_index "gpx_file_tags", :name => "gpx_file_tags_tag_idx"
    remove_index "gpx_files", :name => "gpx_files_user_id_idx"
  end
end
