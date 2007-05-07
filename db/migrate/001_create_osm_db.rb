class CreateOsmDb < ActiveRecord::Migration
  def self.up

    ActiveRecord::Schema.define(:version => 0) do

      create_table "area_segments", :force => true do |t|
        t.column "segment_id",  :integer
        t.column "version",     :integer, :limit => 20, :default => 0, :null => false
        t.column "sequence_id", :integer,                              :null => false
      end

      add_index "area_segments", ["id"], :name => "area_segments_id_idx"
      add_index "area_segments", ["segment_id"], :name => "area_segments_segment_id_idx"
      add_index "area_segments", ["id", "version"], :name => "area_segments_id_version_idx"

      create_table "area_tags", :force => true do |t|
        t.column "k",           :string
        t.column "v",           :string
        t.column "version",     :integer, :limit => 20, :default => 0, :null => false
        t.column "sequence_id", :integer,                              :null => false
      end

      create_table "areas", :force => true do |t|
        t.column "user_id",   :integer,  :limit => 20
        t.column "timestamp", :datetime
        t.column "version",   :integer,  :limit => 20,                   :null => false
        t.column "visible",   :boolean,                :default => true
      end

      create_table "current_nodes", :force => true do |t|
        t.column "latitude",  :float
        t.column "longitude", :float
        t.column "user_id",   :integer,  :limit => 20
        t.column "visible",   :boolean
        t.column "tags",      :text,                   :default => "", :null => false
        t.column "timestamp", :datetime
      end

      add_index "current_nodes", ["id"], :name => "current_nodes_id_idx"
      add_index "current_nodes", ["latitude", "longitude"], :name => "current_nodes_lat_lon_idx"

      create_table "current_segments", :force => true do |t|
        t.column "node_a",    :integer,  :limit => 64
        t.column "node_b",    :integer,  :limit => 64
        t.column "user_id",   :integer,  :limit => 20
        t.column "visible",   :boolean
        t.column "tags",      :text,                   :default => "", :null => false
        t.column "timestamp", :datetime
      end

      add_index "current_segments", ["id", "visible"], :name => "current_segments_id_visible_idx"
      add_index "current_segments", ["node_a"], :name => "current_segments_a_idx"
      add_index "current_segments", ["node_b"], :name => "current_segments_b_idx"

      create_table "current_way_segments", :force => true do |t|
        t.column "segment_id",  :integer
        t.column "sequence_id", :integer
      end

      add_index "current_way_segments", ["segment_id"], :name => "current_way_segments_seg_idx"
      add_index "current_way_segments", ["id"], :name => "current_way_segments_id_idx"

      create_table "current_way_tags", :force => true do |t|
        t.column "k", :string, :default => "", :null => false
        t.column "v", :string, :default => "", :null => false
      end

      add_index "current_way_tags", ["id"], :name => "current_way_tags_id_idx"
      add_index "current_way_tags", ["v"], :name => "current_way_tags_v_idx"

      create_table "current_ways", :force => true do |t|
        t.column "user_id",   :integer,  :limit => 20
        t.column "timestamp", :datetime
        t.column "visible",   :boolean
      end

      add_index "current_ways", ["id", "visible"], :name => "current_ways_id_visible_idx"

      create_table "diary_entries", :force => true do |t|
        t.column "user_id",    :integer,  :limit => 20, :null => false
        t.column "title",      :string
        t.column "body",       :text
        t.column "created_at", :datetime
        t.column "updated_at", :datetime
      end

      create_table "friends", :force => true do |t|
        t.column "user_id",        :integer, :limit => 20, :null => false
        t.column "friend_user_id", :integer, :limit => 20, :null => false
      end

      add_index "friends", ["friend_user_id"], :name => "user_id_idx"

      create_table "gps_points", :id => false, :force => true do |t|
        t.column "altitude",  :float
        t.column "user_id",   :integer,  :limit => 20
        t.column "trackid",   :integer
        t.column "latitude",  :integer
        t.column "longitude", :integer
        t.column "gpx_id",    :integer,  :limit => 20
        t.column "timestamp", :datetime
      end

      add_index "gps_points", ["latitude", "longitude", "user_id"], :name => "points_idx"
      add_index "gps_points", ["user_id"], :name => "points_uid_idx"
      add_index "gps_points", ["gpx_id"], :name => "points_gpxid_idx"

      create_table "gpx_file_tags", :force => true do |t|
        t.column "gpx_id", :integer, :limit => 64, :default => 0, :null => false
        t.column "tag",    :string
      end

      add_index "gpx_file_tags", ["gpx_id"], :name => "gpx_file_tags_gpxid_idx"

      create_table "gpx_files", :force => true do |t|
        t.column "user_id",     :integer,  :limit => 20
        t.column "visible",     :boolean,                :default => true, :null => false
        t.column "name",        :string,                 :default => "",   :null => false
        t.column "size",        :integer,  :limit => 20
        t.column "latitude",    :float
        t.column "longitude",   :float
        t.column "timestamp",   :datetime
        t.column "public",      :boolean,                :default => true, :null => false
        t.column "description", :string,                 :default => ""
        t.column "inserted",    :boolean
      end

      add_index "gpx_files", ["timestamp"], :name => "gpx_files_timestamp_idx"
      add_index "gpx_files", ["visible", "public"], :name => "gpx_files_visible_public_idx"

      create_table "gpx_pending_files", :id => false, :force => true do |t|
        t.column "originalname", :string
        t.column "tmpname",      :string
        t.column "user_id",      :integer, :limit => 20
      end

      create_table "messages", :force => true do |t|
        t.column "title",             :string
        t.column "body",              :text
        t.column "sent_on",           :datetime
        t.column "message_read",      :boolean,                :default => false
        t.column "from_user_id",      :integer,  :limit => 20,                    :null => false
        t.column "to_user_id",        :integer,  :limit => 20, :default => 0,     :null => false
        t.column "from_display_name", :string,                 :default => ""
      end

      add_index "messages", ["from_display_name"], :name => "from_name_idx"

      create_table "meta_areas", :force => true do |t|
        t.column "user_id",   :integer,  :limit => 20
        t.column "timestamp", :datetime
      end

      create_table "nodes", :force => true do |t|
        t.column "latitude",  :float
        t.column "longitude", :float
        t.column "user_id",   :integer,  :limit => 20
        t.column "visible",   :boolean
        t.column "tags",      :text,                   :default => "", :null => false
        t.column "timestamp", :datetime
      end

      add_index "nodes", ["id"], :name => "nodes_uid_idx"
      add_index "nodes", ["latitude", "longitude"], :name => "nodes_latlon_idx"

      create_table "segments", :force => true do |t|
        t.column "node_a",    :integer,  :limit => 64
        t.column "node_b",    :integer,  :limit => 64
        t.column "user_id",   :integer,  :limit => 20
        t.column "visible",   :boolean
        t.column "tags",      :text,                   :default => "", :null => false
        t.column "timestamp", :datetime
      end

      add_index "segments", ["node_a"], :name => "street_segments_nodea_idx"
      add_index "segments", ["node_b"], :name => "street_segments_nodeb_idx"
      add_index "segments", ["id"], :name => "street_segment_uid_idx"

      create_table "users", :force => true do |t|
        t.column "email",         :string
        t.column "token",         :string
        t.column "active",        :integer,                :default => 0,     :null => false
        t.column "pass_crypt",    :string
        t.column "creation_time", :datetime
        t.column "timeout",       :datetime
        t.column "display_name",  :string,                 :default => ""
        t.column "preferences",   :text
        t.column "data_public",   :boolean,                :default => false
        t.column "description",   :text,                   :default => "",    :null => false
        t.column "home",          :integer,  :limit => 64
        t.column "home_lat",      :float
        t.column "home_lon",      :float
        t.column "within_lat",    :float
        t.column "within_lon",    :float
      end

      add_index "users", ["email"], :name => "users_email_idx"
      add_index "users", ["display_name"], :name => "users_display_name_idx"

      create_table "way_segments", :force => true do |t|
        t.column "segment_id",  :integer
        t.column "version",     :integer, :limit => 20, :default => 0, :null => false
        t.column "sequence_id", :integer,                              :null => false
      end

      create_table "way_tags", :force => true do |t|
        t.column "k",       :string
        t.column "v",       :string
        t.column "version", :integer, :limit => 20
      end

      add_index "way_tags", ["id", "version"], :name => "way_tags_id_version_idx"

      create_table "ways", :force => true do |t|
        t.column "user_id",   :integer,  :limit => 20
        t.column "timestamp", :datetime
        t.column "version",   :integer,  :limit => 20,                   :null => false
        t.column "visible",   :boolean,                :default => true
      end

      add_index "ways", ["id"], :name => "ways_id_version_idx"

    end
  end

  def self.down
    
  end
end
