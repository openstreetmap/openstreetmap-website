require "migrate"

class CreateOsmDb < ActiveRecord::Migration
  def self.up

    create_table "current_nodes", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "latitude",  :integer, :null => false
      t.column "longitude", :integer, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "tile",      :bigint, :null => false
      t.column "version", :bigint, :null => false
    end

    add_index "current_nodes", ["timestamp"], :name => "current_nodes_timestamp_idx"
    add_index "current_nodes", ["tile"], :name => "current_nodes_tile_idx"

    create_table :current_node_tags, :id => false do |t|
      t.column :node_id,          :bigint, :null => false
      t.column :k,           :string, :default => "", :null => false
      t.column :v,           :string, :default => "", :null => false
    end
    add_primary_key :current_node_tags, [:node_id, :k]
    add_foreign_key :current_node_tags, :current_nodes, :column => :node_id, :name => "current_node_tags_id_fkey"

    create_table "current_ways", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "version", :bigint, :null => false
    end
    add_index :current_ways, :timestamp, :name => :current_ways_timestamp_idx
  
    create_table :current_way_nodes, :id => false do |t|
      t.column :id,          :bigint, :null => false
      t.column :node_id,     :bigint, :null => false
      t.column :sequence_id, :bigint, :null => false
    end
    add_primary_key :current_way_nodes, [:id, :sequence_id]
    add_index :current_way_nodes, [:node_id], :name => "current_way_nodes_node_idx"
    add_foreign_key :current_way_nodes, :current_nodes, :column => :node_id, :name => "current_way_nodes_node_id_fkey"
    add_foreign_key :current_way_nodes, :current_ways, :column => :id, :name => "current_way_nodes_id_fkey"
   
    create_table "current_way_tags", :id => false do |t|
      t.column "id", :bigint, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end
    add_primary_key :current_way_tags, [:id, :k]
    add_foreign_key :current_way_tags, :current_ways, :column => :id, :name => "current_way_tags_id_fkey"

   
    create_table "diary_entries", :id => false do |t|
      t.column "id",         :bigserial, :primary_key => true, :null => false
      t.column "user_id",    :bigint, :null => false
      t.column "title",      :string, :null => false
      t.column "body",       :text, :null => false
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "latitude", :float, :limit => 53
      t.column "longitude", :float, :limit => 53
      t.column "language_code", :string, :null => false, :default => "en"
      t.column :visible, :boolean, :null => false, :default => true
    end

    add_index :diary_entries, [:created_at], :name => "diary_entry_created_at_index"
    add_index :diary_entries, [:user_id, :created_at], :name => "diary_entry_user_id_created_at_index"
    add_index :diary_entries, [:language_code, :created_at], :name => "diary_entry_language_code_created_at_index"
 
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
      t.column  "tile", :bigint
    end

    add_index "gps_points", ["gpx_id"], :name => "points_gpxid_idx"
    add_index "gps_points", ["tile"], :name => "points_tile_idx"

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
    add_index "gpx_files", ["user_id"], :name => "gpx_files_user_id_idx"
    add_index "gpx_file_tags", ["tag"], :name => "gpx_file_tags_tag_idx"


    create_table "messages", :id => false do |t|
      t.column "id",                :bigserial, :primary_key => true, :null => false
      t.column "from_user_id",      :bigint, :null => false
      t.column "title",             :string, :null => false
      t.column "body",              :text, :null => false
      t.column "sent_on",           :datetime, :null => false
      t.column "message_read",      :boolean, :default => false, :null => false
      t.column "to_user_id",        :bigint, :null => false
      t.column :to_user_visible, :boolean, :default => true, :null => false
      t.column :from_user_visible, :boolean, :default => true, :null => false
    end

    add_index "messages", ["to_user_id"], :name => "messages_to_user_id_idx"
    add_index :messages, [:from_user_id], :name => "messages_from_user_id_idx"
 
    create_table "nodes", :id => false do |t|
      t.column "node_id",        :bigint, :null => false
      t.column "latitude",  :integer, :null => false
      t.column "longitude", :integer, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "tile",      :bigint, :null => false
      t.column :version, :bigint, :null => false
    end

    add_primary_key :nodes, [:node_id, :version]
    add_index "nodes", ["timestamp"], :name => "nodes_timestamp_idx"
    add_index "nodes", ["tile"], :name => "nodes_tile_idx"

    create_table :node_tags, :id => false do |t|
      t.column :node_id,          :bigint, :null => false
      t.column :version,     :bigint, :null => false
      t.column :k,       :string, :default => "", :null => false
      t.column :v,       :string, :default => "", :null => false
    end
    add_primary_key :node_tags, [:node_id, :version, :k]
    add_foreign_key :node_tags, :nodes, :column => [:node_id, :version], :primary_key => [:node_id, :version], :name => "node_tags_id_fkey"

    create_enumeration :user_status_enum, %w(pending active confirmed suspended deleted)

    create_table "users", :id => false do |t|
      t.column "email",         :string, :null => false
      t.column "id",            :bigserial, :primary_key => true, :null => false
      t.column "pass_crypt",    :string, :null => false
      t.column "creation_time", :datetime, :null => false
      t.column "display_name",  :string, :default => "", :null => false
      t.column "data_public",   :boolean, :default => false, :null => false
      t.column "description",   :text, :default => "", :null => false
      t.column "home_lat",      :float, :limit => 53, :default => nil
      t.column "home_lon",      :float, :limit => 53, :default => nil
      t.column "home_zoom",     :integer, :limit => 2, :default => 3
      t.column "email_valid", :boolean, :default => false, :null => false
      t.column "new_email", :string
      t.column :status, :user_status_enum, :null => false, :default => "pending"
      t.column "creation_ip", :string
      t.column "image_file_name", :text
      t.column "nearby", :integer, :default => 50
      t.column "pass_salt", :string
      t.column "languages", :string
      t.column :terms_agreed, :datetime
      t.column :consider_pd, :boolean, :null => false, :default => false
      t.column :preferred_editor, :string
      t.column :terms_seen, :boolean, :null => false, :default => false
      t.column :image_fingerprint, :string, :null => true
      t.column :changesets_count, :integer, :null => false, :default => 0
      t.column :traces_count, :integer, :null => false, :default => 0
      t.column :image_content_type, :string
      t.column :diary_entries_count, :integer, :null => false, :default => 0
      t.column :image_use_gravatar, :boolean, :null => false, :default => true
      t.column :auth_uid, :string
      t.column :auth_provider, :string
    end

    add_index "users", ["email"], :name => "users_email_idx", :unique => true
    add_index "users", ["display_name"], :name => "users_display_name_idx", :unique => true
    add_index :users, [], :columns => "LOWER(display_name)", :name => "users_display_name_lower_idx"
    add_index :users, [], :columns => "LOWER(email)", :name => "users_email_lower_idx"
    add_index :users, [:auth_provider, :auth_uid], :unique => true, :name => "users_auth_idx"

    create_table "user_preferences", :id => false do |t|
      t.column "user_id", :bigint, :null => false
      t.column "k", :string, :null => false
      t.column "v", :string, :null => false
    end

    add_primary_key "user_preferences", %w(user_id k)

    create_table "user_tokens", :id => false do |t|
      t.column "id", :bigserial, :primary_key => true, :null => false
      t.column "user_id", :bigint, :null => false
      t.column "token", :string, :null => false
      t.column "expiry", :datetime, :null => false
      t.column :referer, :text
    end
 

    add_index "user_tokens", ["token"], :name => "user_tokens_token_idx", :unique => true
    add_index "user_tokens", ["user_id"], :name => "user_tokens_user_id_idx"

    create_table "ways", :id => false do |t|
      t.column "id",        :bigint, :default => 0, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "version",   :bigint, :null => false
      t.column "visible",   :boolean, :default => true, :null => false
    end

    add_primary_key "ways", %w(id version)
    add_index "ways", ["timestamp"], :name => "ways_timestamp_idx"

    create_table :way_nodes, :id => false do |t|
      t.column :id,          :bigint, :null => false
      t.column :node_id,     :bigint, :null => false
      t.column :version,     :bigint, :null => false
      t.column :sequence_id, :bigint, :null => false
    end
    add_primary_key :way_nodes, [:id, :version, :sequence_id]
    add_foreign_key :way_nodes, :ways, :column => [:id, :version], :primary_key => [:id, :version], :name => "way_nodes_id_fkey"
    add_index "way_nodes", ["node_id"], :name => "way_nodes_node_idx"

    create_table "way_tags", :id => false do |t|
      t.column "id",      :bigint, :default => 0, :null => false
      t.column "k",       :string, :null => false
      t.column "v",       :string, :null => false
      t.column "version", :bigint, :null => false
    end
    add_primary_key :way_tags, [:id, :version, :k]
    add_foreign_key :way_tags, :ways, :column => [:id, :version], :primary_key => [:id, :version], :name => "way_tags_id_fkey"


    create_enumeration :format_enum, %w(html markdown text)
    add_column :users, :description_format, :format_enum, :null => false, :default => "markdown"
    add_column :diary_entries, :body_format, :format_enum, :null => false, :default => "markdown"
    add_column :diary_comments, :body_format, :format_enum, :null => false, :default => "markdown"
    add_column :messages, :body_format, :format_enum, :null => false, :default => "markdown"
  
  end

  def self.down
  end
end
