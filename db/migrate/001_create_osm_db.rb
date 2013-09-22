require 'migrate'

class CreateOsmDb < ActiveRecord::Migration
  def self.up
    create_table "current_nodes", innodb_table do |t|
      t.column "id",        :bigint,   :limit => 64,                 :null => false
      t.column "latitude",  :double
      t.column "longitude", :double
      t.column "user_id",   :bigint,   :limit => 20
      t.column "visible",   :boolean
      t.column "tags",      :text,                   :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "current_nodes", ["id"], :name => "current_nodes_id_idx"
    add_index "current_nodes", ["latitude", "longitude"], :name => "current_nodes_lat_lon_idx"
    add_index "current_nodes", ["timestamp"], :name => "current_nodes_timestamp_idx"

    change_column :current_nodes, :id, :bigint_auto_64

    create_table "current_segments", innodb_table do |t|
      t.column "id",        :bigint,   :limit => 64,                 :null => false
      t.column "node_a",    :bigint,   :limit => 64
      t.column "node_b",    :bigint,   :limit => 64
      t.column "user_id",   :bigint,   :limit => 20
      t.column "visible",   :boolean
      t.column "tags",      :text,                   :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "current_segments", ["id", "visible"], :name => "current_segments_id_visible_idx"
    add_index "current_segments", ["node_a"], :name => "current_segments_a_idx"
    add_index "current_segments", ["node_b"], :name => "current_segments_b_idx"

    change_column :current_segments, :id, :bigint_auto_64

    create_table "current_way_segments", innodb_table do |t|
      t.column "id",          :bigint, :limit => 64
      t.column "segment_id",  :bigint, :limit => 11
      t.column "sequence_id", :bigint, :limit => 11
    end

    add_index "current_way_segments", ["segment_id"], :name => "current_way_segments_seg_idx"
    add_index "current_way_segments", ["id"], :name => "current_way_segments_id_idx"

    create_table "current_way_tags", myisam_table do |t|
      t.column "id", :bigint, :limit => 64
      t.column "k",  :string,                :default => "", :null => false
      t.column "v",  :string,                :default => "", :null => false
    end

    add_index "current_way_tags", ["id"], :name => "current_way_tags_id_idx"
    add_fulltext_index "current_way_tags", "v"

    create_table "current_ways", myisam_table do |t|
      t.column "id",        :bigint_pk_64, :null => false
      t.column "user_id",   :bigint,   :limit => 20
      t.column "timestamp", :datetime
      t.column "visible",   :boolean
    end

    create_table "diary_entries", myisam_table do |t|
      t.column "id",         :bigint_pk, :null => false
      t.column "user_id",    :bigint,   :limit => 20, :null => false
      t.column "title",      :string
      t.column "body",       :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "friends", myisam_table do |t|
      t.column "id",             :bigint_pk, :null => false
      t.column "user_id",        :bigint,  :limit => 20, :null => false
      t.column "friend_user_id", :bigint,  :limit => 20, :null => false
    end

    add_index "friends", ["friend_user_id"], :name => "user_id_idx"

    create_table "gps_points", myisam_table do |t|
      t.column "altitude",  :float
      t.column "user_id",   :integer
      t.column "trackid",   :integer
      t.column "latitude",  :integer
      t.column "longitude", :integer
      t.column "gpx_id",    :integer
      t.column "timestamp", :datetime
    end

    add_index "gps_points", ["latitude", "longitude", "user_id"], :name => "points_idx"
    add_index "gps_points", ["user_id"], :name => "points_uid_idx"
    add_index "gps_points", ["gpx_id"], :name => "points_gpxid_idx"

    create_table "gpx_file_tags", myisam_table do |t|
      t.column "gpx_id", :bigint,  :limit => 64, :default => 0, :null => false
      t.column "tag",    :string
      t.column "id",     :bigint_pk, :null => false
    end

    add_index "gpx_file_tags", ["gpx_id"], :name => "gpx_file_tags_gpxid_idx"

    create_table "gpx_files", myisam_table do |t|
      t.column "id",          :bigint_pk_64,                   :null => false
      t.column "user_id",     :bigint,   :limit => 20
      t.column "visible",     :boolean,                :default => true, :null => false
      t.column "name",        :string,                 :default => "",   :null => false
      t.column "size",        :bigint,   :limit => 20
      t.column "latitude",    :double
      t.column "longitude",   :double
      t.column "timestamp",   :datetime
      t.column "public",      :boolean,                :default => true, :null => false
      t.column "description", :string,                 :default => ""
      t.column "inserted",    :boolean
    end

    add_index "gpx_files", ["timestamp"], :name => "gpx_files_timestamp_idx"
    add_index "gpx_files", ["visible", "public"], :name => "gpx_files_visible_public_idx"

    create_table "gpx_pending_files", myisam_table do |t|
      t.column "originalname", :string
      t.column "tmpname",      :string
      t.column "user_id",      :bigint,  :limit => 20
    end

    create_table "messages", myisam_table do |t|
      t.column "id",                :bigint_pk,                                 :null => false
      t.column "user_id",           :bigint,   :limit => 20,                    :null => false
      t.column "from_user_id",      :bigint,   :limit => 20,                    :null => false
      t.column "from_display_name", :string,                 :default => ""
      t.column "title",             :string
      t.column "body",              :text
      t.column "sent_on",           :datetime
      t.column "message_read",      :boolean,                :default => false
      t.column "to_user_id",        :bigint,   :limit => 20,                    :null => false
    end

    add_index "messages", ["from_display_name"], :name => "from_name_idx"

    create_table "meta_areas", myisam_table do |t|
      t.column "id",        :bigint_pk_64, :null => false
      t.column "user_id",   :bigint,  :limit => 20
      t.column "timestamp", :datetime
    end

    create_table "nodes", myisam_table do |t|
      t.column "id",        :bigint,  :limit => 64
      t.column "latitude",  :double
      t.column "longitude", :double
      t.column "user_id",   :bigint,  :limit => 20
      t.column "visible",   :boolean
      t.column "tags",      :text,                  :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "nodes", ["id"], :name => "nodes_uid_idx"
    add_index "nodes", ["latitude", "longitude"], :name => "nodes_latlon_idx"

    create_table "segments", myisam_table do |t|
      t.column "id",        :bigint,  :limit => 64
      t.column "node_a",    :bigint,  :limit => 64
      t.column "node_b",    :bigint,  :limit => 64
      t.column "user_id",   :bigint,  :limit => 20
      t.column "visible",   :boolean
      t.column "tags",      :text,                  :default => "", :null => false
      t.column "timestamp", :datetime
    end

    add_index "segments", ["node_a"], :name => "street_segments_nodea_idx"
    add_index "segments", ["node_b"], :name => "street_segments_nodeb_idx"
    add_index "segments", ["id"], :name => "street_segment_uid_idx"

    create_table "users", innodb_table do |t|
      t.column "email",         :string
      t.column "id",            :bigint_pk,                    :null => false
      t.column "token",         :string
      t.column "active",        :integer,                :default => 0,     :null => false
      t.column "pass_crypt",    :string
      t.column "creation_time", :datetime
      t.column "timeout",       :datetime
      t.column "display_name",  :string,                 :default => ""
      t.column "preferences",   :text
      t.column "data_public",   :boolean,                :default => false
      t.column "description",   :text,                   :default => "",    :null => false
      t.column "home_lat",      :double,                 :default => 1
      t.column "home_lon",      :double,                 :default => 1
      t.column "within_lon",    :double
      t.column "within_lat",    :double
      t.column "home_zoom",     :integer,  :limit => 2,  :default => 3
    end

    add_index "users", ["email"], :name => "users_email_idx"
    add_index "users", ["display_name"], :name => "users_display_name_idx"

    create_table "way_segments", myisam_table do |t|
      t.column "id",          :bigint,  :limit => 64, :default => 0, :null => false
      t.column "segment_id",  :integer
      t.column "version",     :bigint,  :limit => 20, :default => 0, :null => false
      t.column "sequence_id", :bigint,  :limit => 11,                :null => false
    end

    add_primary_key "way_segments", ["id", "version", "sequence_id"]

    change_column "way_segments", "sequence_id", :bigint_auto_11

    create_table "way_tags", myisam_table do |t|
      t.column "id",      :bigint,  :limit => 64, :default => 0, :null => false
      t.column "k",       :string
      t.column "v",       :string
      t.column "version", :bigint,  :limit => 20
    end

    add_index "way_tags", ["id", "version"], :name => "way_tags_id_version_idx"

    create_table "ways", myisam_table do |t|
      t.column "id",        :bigint,   :limit => 64, :default => 0, :null => false
      t.column "user_id",   :bigint,   :limit => 20
      t.column "timestamp", :datetime
      t.column "version",   :bigint,   :limit => 20,                   :null => false
      t.column "visible",   :boolean,                :default => true
    end

    add_primary_key "ways", ["id", "version"]
    add_index "ways", ["id"], :name => "ways_id_version_idx"

    change_column "ways", "version", :bigint_auto_20
  end

  def self.down
    
  end
end
