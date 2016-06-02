require "migrate"

class CreateOsmDb < ActiveRecord::Migration
  def self.up
    create_table "current_nodes", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "latitude",  :float, :limit => 53, :null => false
      t.column "longitude", :float, :limit => 53, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
    end

    add_primary_key "current_nodes", ["id"]

    add_index "current_nodes", %w(latitude longitude), :name => "current_nodes_lat_lon_idx"
    add_index "current_nodes", ["timestamp"], :name => "current_nodes_timestamp_idx"

    create_table "current_segments", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "node_a",    :bigint, :null => false
      t.column "node_b",    :bigint, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
    end

    add_primary_key "current_segments", ["id"]

    add_index "current_segments", ["node_a"], :name => "current_segments_a_idx"
    add_index "current_segments", ["node_b"], :name => "current_segments_b_idx"
    
    create_table "current_way_segments", :id => false do |t|
      t.column "id",          :bigint, :null => false
      t.column "segment_id",  :bigint, :null => false
      t.column "sequence_id", :bigint, :null => false
    end

    add_primary_key "current_way_segments", %w(id sequence_id)

    add_index "current_way_segments", ["segment_id"], :name => "current_way_segments_seg_idx"

    create_table "current_way_tags", :id => false do |t|
      t.column "id", :bigint, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    add_index "current_way_tags", ["id"], :name => "current_way_tags_id_idx"
    add_index "current_way_tags", "v", :name => "current_way_tags_v_idx"

    create_table "current_ways", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "visible",   :boolean, :null => false
    end

    create_table "diary_entries", :id => false do |t|
      t.column "id",         :bigserial, :primary_key => true, :null => false
      t.column "user_id",    :bigint, :null => false
      t.column "title",      :string, :null => false
      t.column "body",       :text, :null => false
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
    end

    create_table "friends", :id => false do |t|
      t.column "id",             :bigserial, :primary_key => true, :null => false
      t.column "user_id",        :bigint, :null => false
      t.column "friend_user_id", :bigint, :null => false
    end

    add_index "friends", ["friend_user_id"], :name => "user_id_idx"
    add_index "friends", ["user_id"], :name => "friends_user_id_idx"


    create_table "gps_points", :id => false do |t|
      t.column "altitude",  :float
      t.column "trackid",   :integer, :null => false
      t.column "latitude",  :integer, :null => false
      t.column "longitude", :integer, :null => false
      t.column "gpx_id",    :bigint, :null => false
      t.column "timestamp", :datetime
    end


    add_index "gps_points", ["gpx_id"], :name => "points_gpxid_idx"
    add_index "gps_points", %w(latitude longitude), :name => "points_idx"

    create_table "gpx_file_tags", :id => false do |t|
      t.column "gpx_id", :bigint, :default => 0, :null => false
      t.column "tag",    :string, :null => false
      t.column "id",     :bigserial, :primary_key => true, :null => false
    end

    add_index "gpx_file_tags", ["gpx_id"], :name => "gpx_file_tags_gpxid_idx"

    create_table "gpx_files", :id => false do |t|
      t.column "id",          :bigserial, :primary_key => true, :null => false
      t.column "user_id",     :bigint, :null => false
      t.column "visible",     :boolean, :default => true, :null => false
      t.column "name",        :string, :default => "", :null => false
      t.column "size",        :bigint
      t.column "latitude",    :float, :limit => 53
      t.column "longitude",   :float, :limit => 53
      t.column "timestamp",   :datetime, :null => false
      t.column "public",      :boolean, :default => true, :null => false
      t.column "description", :string, :default => "", :null => false
      t.column "inserted",    :boolean, :null => false
    end

    add_index "gpx_files", ["timestamp"], :name => "gpx_files_timestamp_idx"
    add_index "gpx_files", %w(visible public), :name => "gpx_files_visible_public_idx"


    create_table "messages", :id => false do |t|
      t.column "id",                :bigserial, :primary_key => true, :null => false
      t.column "from_user_id",      :bigint, :null => false
      t.column "title",             :string, :null => false
      t.column "body",              :text, :null => false
      t.column "sent_on",           :datetime, :null => false
      t.column "message_read",      :boolean, :default => false, :null => false
      t.column "to_user_id",        :bigint, :null => false
    end

    add_index "messages", ["to_user_id"], :name => "messages_to_user_id_idx"
 
    create_table "nodes", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "latitude",  :float, :limit => 53, :null => false
      t.column "longitude", :float, :limit => 53, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
    end

    add_index "nodes", ["id"], :name => "nodes_uid_idx"
    add_index "nodes", %w(latitude longitude), :name => "nodes_latlon_idx"
    add_index "nodes", ["timestamp"], :name => "nodes_timestamp_idx"

    create_table "segments", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "node_a",    :bigint, :null => false
      t.column "node_b",    :bigint, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
    end

    add_index "segments", ["node_a"], :name => "street_segments_nodea_idx"
    add_index "segments", ["node_b"], :name => "street_segments_nodeb_idx"
    add_index "segments", ["id"], :name => "street_segment_uid_idx"
    add_index "segments", ["timestamp"], :name => "segments_timestamp_idx"

    create_table "users", :id => false do |t|
      t.column "email",         :string, :null => false
      t.column "id",            :bigserial, :primary_key => true, :null => false
      t.column "token",         :string
      t.column "active",        :integer, :default => 0, :null => false
      t.column "pass_crypt",    :string, :null => false
      t.column "creation_time", :datetime, :null => false
      t.column "timeout",       :datetime, :null => false
      t.column "display_name",  :string, :default => "", :null => false
      t.column "data_public",   :boolean, :default => false, :null => false
      t.column "description",   :text, :default => "", :null => false
      t.column "home_lat",      :float, :limit => 53, :default => nil
      t.column "home_lon",      :float, :limit => 53, :default => nil
      t.column "within_lon",    :float, :limit => 53
      t.column "within_lat",    :float, :limit => 53
      t.column "home_zoom",     :integer, :limit => 2, :default => 3
    end

    add_index "users", ["email"], :name => "users_email_idx", :unique => true
    add_index "users", ["display_name"], :name => "users_display_name_idx", :unique => true

    create_table "way_segments", :id => false do |t|
      t.column "id",          :bigint, :default => 0, :null => false
      t.column "segment_id",  :integer, :null => false
      t.column "version",     :bigint, :default => 0, :null => false
      t.column "sequence_id", :bigint, :null => false
    end

    add_primary_key "way_segments", %w(id version sequence_id)

    create_table "way_tags", :id => false do |t|
      t.column "id",      :bigint, :default => 0, :null => false
      t.column "k",       :string, :null => false
      t.column "v",       :string, :null => false
      t.column "version", :bigint, :null => false
    end

    add_index "way_tags", %w(id version), :name => "way_tags_id_version_idx"

    create_table "ways", :id => false do |t|
      t.column "id",        :bigint, :default => 0, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "version",   :bigint, :null => false
      t.column "visible",   :boolean, :default => true, :null => false
    end

    add_index "ways", ["timestamp"], :name => "ways_timestamp_idx"

    add_primary_key "ways", %w(id version)

  end

  def self.down
  end
end
