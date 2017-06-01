require "migrate"

class CleanupOsmDb < ActiveRecord::Migration
  def self.up
    change_column "current_nodes", "latitude", :float, :limit => 53, :null => false
    change_column "current_nodes", "longitude", :float, :limit => 53, :null => false
    change_column "current_nodes", "user_id", :bigint, :null => false
    change_column "current_nodes", "visible", :boolean, :null => false
    change_column "current_nodes", "timestamp", :datetime, :null => false
    add_primary_key "current_nodes", ["id"]
    remove_index "current_nodes", :name => "current_nodes_id_idx"

    change_column "current_segments", "node_a", :bigint, :null => false
    change_column "current_segments", "node_b", :bigint, :null => false
    change_column "current_segments", "user_id", :bigint, :null => false
    change_column "current_segments", "visible", :boolean, :null => false
    change_column "current_segments", "timestamp", :datetime, :null => false
    add_primary_key "current_segments", ["id"]
    remove_index "current_segments", :name => "current_segments_id_visible_idx"

    change_column "current_way_segments", "id", :bigint, :null => false
    change_column "current_way_segments", "segment_id", :bigint, :null => false
    change_column "current_way_segments", "sequence_id", :bigint, :null => false
    add_primary_key "current_way_segments", %w[id sequence_id]
    remove_index "current_way_segments", :name => "current_way_segments_id_idx"

    change_column "current_way_tags", "id", :bigint, :null => false

    change_column "current_ways", "user_id", :bigint, :null => false
    change_column "current_ways", "timestamp", :datetime, :null => false
    change_column "current_ways", "visible", :boolean, :null => false

    change_column "diary_entries", "title", :string, :null => false
    change_column "diary_entries", "body", :text, :null => false
    change_column "diary_entries", "created_at", :datetime, :null => false
    change_column "diary_entries", "updated_at", :datetime, :null => false

    add_index "friends", ["user_id"], :name => "friends_user_id_idx"

    remove_index "gps_points", :name => "points_uid_idx"
    remove_index "gps_points", :name => "points_idx"
    remove_column "gps_points", "user_id"
    add_index "gps_points", %w[latitude longitude], :name => "points_idx"
    change_column "gps_points", "trackid", :integer, :null => false
    change_column "gps_points", "latitude", :integer, :null => false
    change_column "gps_points", "longitude", :integer, :null => false
    change_column "gps_points", "gpx_id", :bigint, :null => false

    change_column "gpx_file_tags", "tag", :string, :null => false

    change_column "gpx_files", "user_id", :bigint, :null => false
    change_column "gpx_files", "timestamp", :datetime, :null => false
    change_column "gpx_files", "description", :string, :default => "", :null => false
    change_column "gpx_files", "inserted", :boolean, :null => false

    drop_table "gpx_pending_files"

    remove_index "messages", :name => "from_name_idx"
    remove_column "messages", "user_id"
    remove_column "messages", "from_display_name"
    change_column "messages", "title", :string, :null => false
    change_column "messages", "body", :text, :null => false
    change_column "messages", "sent_on", :datetime, :null => false
    change_column "messages", "message_read", :boolean, :default => false, :null => false
    add_index "messages", ["to_user_id"], :name => "messages_to_user_id_idx"

    drop_table "meta_areas"

    change_column "nodes", "id", :bigint, :null => false
    change_column "nodes", "latitude", :float, :limit => 53, :null => false
    change_column "nodes", "longitude", :float, :limit => 53, :null => false
    change_column "nodes", "user_id", :bigint, :null => false
    change_column "nodes", "visible", :boolean, :null => false
    change_column "nodes", "timestamp", :datetime, :null => false
    add_index "nodes", ["timestamp"], :name => "nodes_timestamp_idx"

    change_column "segments", "id", :bigint, :null => false
    change_column "segments", "node_a", :bigint, :null => false
    change_column "segments", "node_b", :bigint, :null => false
    change_column "segments", "user_id", :bigint, :null => false
    change_column "segments", "visible", :boolean, :null => false
    change_column "segments", "timestamp", :datetime, :null => false
    add_index "segments", ["timestamp"], :name => "segments_timestamp_idx"

    remove_column "users", "preferences"
    change_column "users", "email", :string, :null => false
    change_column "users", "pass_crypt", :string, :null => false
    change_column "users", "creation_time", :datetime, :null => false
    change_column "users", "display_name", :string, :default => "", :null => false
    change_column "users", "data_public", :boolean, :default => false, :null => false
    change_column "users", "home_lat", :float, :limit => 53, :default => nil
    change_column "users", "home_lon", :float, :limit => 53, :default => nil
    remove_index "users", :name => "users_email_idx"
    add_index "users", ["email"], :name => "users_email_idx", :unique => true
    remove_index "users", :name => "users_display_name_idx"
    add_index "users", ["display_name"], :name => "users_display_name_idx", :unique => true

    change_column "way_segments", "segment_id", :bigint, :null => false

    change_column "way_tags", "k", :string, :null => false
    change_column "way_tags", "v", :string, :null => false
    change_column "way_tags", "version", :bigint, :null => false

    change_column "ways", "user_id", :bigint, :null => false
    change_column "ways", "timestamp", :datetime, :null => false
    change_column "ways", "visible", :boolean, :default => true, :null => false
    remove_index "ways", :name => "ways_id_version_idx"
    add_index "ways", ["timestamp"], :name => "ways_timestamp_idx"
  end

  def self.down
    remove_index "ways", :name => "ways_timestamp_idx"
    add_index "ways", ["id"], :name => "ways_id_version_idx"
    change_column "ways", "visible", :boolean, :default => true
    change_column "ways", "timestamp", :datetime
    change_column "ways", "user_id", :bigint

    change_column "way_tags", "version", :bigint
    change_column "way_tags", "v", :string, :default => nil
    change_column "way_tags", "k", :string, :default => nil

    change_column "way_segments", "segment_id", :integer

    remove_index "users", :name => "users_display_name_idx"
    add_index "users", ["display_name"], :name => "users_display_name_idx"
    remove_index "users", :name => "users_email_idx"
    add_index "users", ["email"], :name => "users_email_idx"
    change_column "users", "home_lon", :float, :limit => 53, :default => 1
    change_column "users", "home_lat", :float, :limit => 53, :default => 1
    change_column "users", "data_public", :boolean, :default => false
    change_column "users", "display_name", :string, :default => ""
    change_column "users", "creation_time", :datetime
    change_column "users", "pass_crypt", :string, :default => nil
    change_column "users", "email", :string, :default => nil
    add_column "users", "preferences", :text

    remove_index "segments", :name => "segments_timestamp_idx"
    change_column "segments", "timestamp", :datetime
    change_column "segments", "visible", :boolean
    change_column "segments", "user_id", :bigint
    change_column "segments", "node_b", :bigint
    change_column "segments", "node_a", :bigint
    change_column "segments", "id", :bigint

    remove_index "nodes", :name => "nodes_timestamp_idx"
    change_column "nodes", "timestamp", :datetime
    change_column "nodes", "visible", :boolean
    change_column "nodes", "user_id", :bigint
    change_column "nodes", "longitude", :float, :limit => 53
    change_column "nodes", "latitude", :float, :limit => 53
    change_column "nodes", "id", :bigint

    create_table "meta_areas", :id => false do |t|
      t.column "id", :bigserial, :primary_key => true, :null => false
      t.column "user_id", :bigint
      t.column "timestamp", :datetime
    end

    remove_index "messages", :name => "messages_to_user_id_idx"
    change_column "messages", "message_read", :boolean, :default => false
    change_column "messages", "sent_on", :datetime
    change_column "messages", "body", :text
    change_column "messages", "title", :string, :default => nil
    add_column "messages", "from_display_name", :string, :default => ""
    add_column "messages", "user_id", :bigint, :null => false
    add_index "messages", ["from_display_name"], :name => "from_name_idx"

    create_table "gpx_pending_files", :id => false do |t|
      t.column "originalname", :string
      t.column "tmpname", :string
      t.column "user_id", :bigint
    end

    change_column "gpx_files", "inserted", :boolean
    change_column "gpx_files", "description", :string, :default => ""
    change_column "gpx_files", "timestamp", :datetime
    change_column "gpx_files", "user_id", :bigint

    change_column "gpx_file_tags", "tag", :string, :default => nil

    change_column "gps_points", "gpx_id", :integer
    change_column "gps_points", "longitude", :integer
    change_column "gps_points", "latitude", :integer
    change_column "gps_points", "trackid", :integer
    add_column "gps_points", "user_id", :integer
    add_index "gps_points", ["user_id"], :name => "points_uid_idx"

    remove_index "friends", :name => "friends_user_id_idx"

    change_column "diary_entries", "updated_at", :datetime
    change_column "diary_entries", "created_at", :datetime
    change_column "diary_entries", "body", :text
    change_column "diary_entries", "title", :string, :default => nil

    change_column "current_ways", "visible", :boolean
    change_column "current_ways", "timestamp", :datetime
    change_column "current_ways", "user_id", :bigint

    change_column "current_way_tags", "id", :bigint

    add_index "current_way_segments", ["id"], :name => "current_way_segments_id_idx"
    remove_primary_key "current_way_segments"
    change_column "current_way_segments", "sequence_id", :bigint
    change_column "current_way_segments", "segment_id", :bigint
    change_column "current_way_segments", "id", :bigint

    add_index "current_segments", %w[id visible], :name => "current_segments_id_visible_idx"
    remove_primary_key "current_segments"
    change_column "current_segments", "timestamp", :datetime
    change_column "current_segments", "visible", :boolean
    change_column "current_segments", "user_id", :bigint
    change_column "current_segments", "node_b", :bigint
    change_column "current_segments", "node_a", :bigint

    add_index "current_nodes", ["id"], :name => "current_nodes_id_idx"
    remove_primary_key "current_nodes"
    change_column "current_nodes", "timestamp", :datetime
    change_column "current_nodes", "visible", :boolean
    change_column "current_nodes", "user_id", :bigint
    change_column "current_nodes", "longitude", :float, :limit => 53
    change_column "current_nodes", "latitude", :float, :limit => 53
  end
end
