require "migrate"

class CreateOsmDb < ActiveRecord::Migration
  def self.up
    create_table "current_nodes", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "latitude",  :float, :limit => 53
      t.column "longitude", :float, :limit => 53
      t.column "user_id",   :bigint
      t.column "visible",   :boolean
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "current_nodes", ["id"], :name => "current_nodes_id_idx"
    add_index "current_nodes", %w(latitude longitude), :name => "current_nodes_lat_lon_idx"
    add_index "current_nodes", ["timestamp"], :name => "current_nodes_timestamp_idx"

    create_table "current_segments", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "node_a",    :bigint
      t.column "node_b",    :bigint
      t.column "user_id",   :bigint
      t.column "visible",   :boolean
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "current_segments", %w(id visible), :name => "current_segments_id_visible_idx"
    add_index "current_segments", ["node_a"], :name => "current_segments_a_idx"
    add_index "current_segments", ["node_b"], :name => "current_segments_b_idx"

    create_table "current_way_segments", :id => false do |t|
      t.column "id",          :bigint
      t.column "segment_id",  :bigint
      t.column "sequence_id", :bigint
    end

    add_index "current_way_segments", ["segment_id"], :name => "current_way_segments_seg_idx"
    add_index "current_way_segments", ["id"], :name => "current_way_segments_id_idx"

    create_table "current_way_tags", :id => false do |t|
      t.column "id", :bigint
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    add_index "current_way_tags", ["id"], :name => "current_way_tags_id_idx"
    add_index "current_way_tags", "v", :name => "current_way_tags_v_idx"

    create_table "current_ways", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "user_id",   :bigint
      t.column "timestamp", :datetime
      t.column "visible",   :boolean
    end

    create_table "diary_entries", :id => false do |t|
      t.column "id",         :bigserial, :primary_key => true, :null => false
      t.column "user_id",    :bigint, :null => false
      t.column "title",      :string
      t.column "body",       :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "friends", :id => false do |t|
      t.column "id",             :bigserial, :primary_key => true, :null => false
      t.column "user_id",        :bigint, :null => false
      t.column "friend_user_id", :bigint, :null => false
    end

    add_index "friends", ["friend_user_id"], :name => "user_id_idx"

    create_table "gps_points", :id => false do |t|
      t.column "altitude",  :float
      t.column "user_id",   :integer
      t.column "trackid",   :integer
      t.column "latitude",  :integer
      t.column "longitude", :integer
      t.column "gpx_id",    :integer
      t.column "timestamp", :datetime
    end

    add_index "gps_points", %w(latitude longitude user_id), :name => "points_idx"
    add_index "gps_points", ["user_id"], :name => "points_uid_idx"
    add_index "gps_points", ["gpx_id"], :name => "points_gpxid_idx"

    create_table "gpx_file_tags", :id => false do |t|
      t.column "gpx_id", :bigint, :default => 0, :null => false
      t.column "tag",    :string
      t.column "id",     :bigserial, :primary_key => true, :null => false
    end

    add_index "gpx_file_tags", ["gpx_id"], :name => "gpx_file_tags_gpxid_idx"

    create_table "gpx_files", :id => false do |t|
      t.column "id",          :bigserial, :primary_key => true, :null => false
      t.column "user_id",     :bigint
      t.column "visible",     :boolean, :default => true, :null => false
      t.column "name",        :string, :default => "", :null => false
      t.column "size",        :bigint
      t.column "latitude",    :float, :limit => 53
      t.column "longitude",   :float, :limit => 53
      t.column "timestamp",   :datetime
      t.column "public",      :boolean, :default => true, :null => false
      t.column "description", :string, :default => ""
      t.column "inserted",    :boolean
    end

    add_index "gpx_files", ["timestamp"], :name => "gpx_files_timestamp_idx"
    add_index "gpx_files", %w(visible public), :name => "gpx_files_visible_public_idx"

    create_table "gpx_pending_files", :id => false do |t|
      t.column "originalname", :string
      t.column "tmpname",      :string
      t.column "user_id",      :bigint
    end

    create_table "messages", :id => false do |t|
      t.column "id",                :bigserial, :primary_key => true, :null => false
      t.column "user_id",           :bigint, :null => false
      t.column "from_user_id",      :bigint, :null => false
      t.column "from_display_name", :string, :default => ""
      t.column "title",             :string
      t.column "body",              :text
      t.column "sent_on",           :datetime
      t.column "message_read",      :boolean, :default => false
      t.column "to_user_id",        :bigint, :null => false
    end

    add_index "messages", ["from_display_name"], :name => "from_name_idx"

    create_table "meta_areas", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "user_id",   :bigint
      t.column "timestamp", :datetime
    end

    create_table "nodes", :id => false do |t|
      t.column "id",        :bigint
      t.column "latitude",  :float, :limit => 53
      t.column "longitude", :float, :limit => 53
      t.column "user_id",   :bigint
      t.column "visible",   :boolean
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "nodes", ["id"], :name => "nodes_uid_idx"
    add_index "nodes", %w(latitude longitude), :name => "nodes_latlon_idx"

    create_table "segments", :id => false do |t|
      t.column "id",        :bigint
      t.column "node_a",    :bigint
      t.column "node_b",    :bigint
      t.column "user_id",   :bigint
      t.column "visible",   :boolean
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "segments", ["node_a"], :name => "street_segments_nodea_idx"
    add_index "segments", ["node_b"], :name => "street_segments_nodeb_idx"
    add_index "segments", ["id"], :name => "street_segment_uid_idx"

    create_table "users", :id => false do |t|
      t.column "email",         :string
      t.column "id",            :bigserial, :primary_key => true, :null => false
      t.column "token",         :string
      t.column "active",        :integer, :default => 0, :null => false
      t.column "pass_crypt",    :string
      t.column "creation_time", :datetime
      t.column "timeout",       :datetime
      t.column "display_name",  :string, :default => ""
      t.column "preferences",   :text
      t.column "data_public",   :boolean, :default => false
      t.column "description",   :text, :default => "", :null => false
      t.column "home_lat",      :float, :limit => 53, :default => 1
      t.column "home_lon",      :float, :limit => 53, :default => 1
      t.column "within_lon",    :float, :limit => 53
      t.column "within_lat",    :float, :limit => 53
      t.column "home_zoom",     :integer, :limit => 2, :default => 3
    end

    add_index "users", ["email"], :name => "users_email_idx"
    add_index "users", ["display_name"], :name => "users_display_name_idx"

    create_table "way_segments", :id => false do |t|
      t.column "id",          :bigint, :default => 0, :null => false
      t.column "segment_id",  :integer
      t.column "version",     :bigint, :default => 0, :null => false
      t.column "sequence_id", :bigint, :null => false
    end

    add_primary_key "way_segments", %w(id version sequence_id)

    create_table "way_tags", :id => false do |t|
      t.column "id",      :bigint, :default => 0, :null => false
      t.column "k",       :string
      t.column "v",       :string
      t.column "version", :bigint
    end

    add_index "way_tags", %w(id version), :name => "way_tags_id_version_idx"

    create_table "ways", :id => false do |t|
      t.column "id",        :bigint, :default => 0, :null => false
      t.column "user_id",   :bigint
      t.column "timestamp", :datetime
      t.column "version",   :bigint, :null => false
      t.column "visible",   :boolean, :default => true
    end

    add_primary_key "ways", %w(id version)
    add_index "ways", ["id"], :name => "ways_id_version_idx"
  end

  def self.down; end
end
