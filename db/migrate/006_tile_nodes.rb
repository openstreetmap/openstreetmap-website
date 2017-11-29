require "migrate"

class TileNodes < ActiveRecord::Migration[5.0]
  def self.upgrade_table(from_table, to_table, model)
    if ENV["USE_DB_FUNCTIONS"]
      execute <<-SQL
      INSERT INTO #{to_table} (id, latitude, longitude, user_id, visible, tags, timestamp, tile)
      SELECT id, ROUND(latitude * 10000000), ROUND(longitude * 10000000),
             user_id, visible, tags, timestamp,
             tile_for_point(CAST(ROUND(latitude * 10000000) AS INTEGER),
                            CAST(ROUND(longitude * 10000000) AS INTEGER))
      FROM #{from_table}
      SQL
    else
      execute <<-SQL
      INSERT INTO #{to_table} (id, latitude, longitude, user_id, visible, tags, timestamp, tile)
      SELECT id, ROUND(latitude * 10000000), ROUND(longitude * 10000000),
             user_id, visible, tags, timestamp, 0
      FROM #{from_table}
      SQL

      model.all.each(&:save!)
    end
  end

  def self.downgrade_table(from_table, to_table)
    execute <<-SQL
    INSERT INTO #{to_table} (id, latitude, longitude, user_id, visible, tags, timestamp)
    SELECT id, latitude / 10000000, longitude / 10000000,
           user_id, visible, tags, timestamp
    FROM #{from_table}
    SQL
  end

  def self.up
    remove_index "current_nodes", :name => "current_nodes_timestamp_idx"

    rename_table "current_nodes", "current_nodes_v5"

    create_table "current_nodes", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "latitude",  :integer, :null => false
      t.column "longitude", :integer, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "tile",      :integer, :null => false
    end

    add_index "current_nodes", ["timestamp"], :name => "current_nodes_timestamp_idx"
    add_index "current_nodes", ["tile"], :name => "current_nodes_tile_idx"

    change_column "current_nodes", "tile", :bigint

    upgrade_table "current_nodes_v5", "current_nodes", Node

    drop_table "current_nodes_v5"

    remove_index "nodes", :name => "nodes_uid_idx"
    remove_index "nodes", :name => "nodes_timestamp_idx"
    rename_table "nodes", "nodes_v5"

    create_table "nodes", :id => false do |t|
      t.column "id",        :bigint, :null => false
      t.column "latitude",  :integer, :null => false
      t.column "longitude", :integer, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "tile",      :integer, :null => false
    end

    add_index "nodes", ["id"], :name => "nodes_uid_idx"
    add_index "nodes", ["timestamp"], :name => "nodes_timestamp_idx"
    add_index "nodes", ["tile"], :name => "nodes_tile_idx"

    change_column "nodes", "tile", :bigint

    upgrade_table "nodes_v5", "nodes", OldNode

    drop_table "nodes_v5"
  end

  def self.down
    rename_table "current_nodes", "current_nodes_v6"

    create_table "current_nodes", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "latitude",  :float, :limit => 53, :null => false
      t.column "longitude", :float, :limit => 53, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false
      t.column "tags",      :text, :default => "", :null => false
      t.column "timestamp", :datetime, :null => false
    end

    add_index "current_nodes", %w[latitude longitude], :name => "current_nodes_lat_lon_idx"
    add_index "current_nodes", ["timestamp"], :name => "current_nodes_timestamp_idx"

    downgrade_table "current_nodes_v6", "current_nodes"

    drop_table "current_nodes_v6"

    rename_table "nodes", "nodes_v6"

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
    add_index "nodes", %w[latitude longitude], :name => "nodes_latlon_idx"
    add_index "nodes", ["timestamp"], :name => "nodes_timestamp_idx"

    downgrade_table "nodes_v6", "nodes"

    drop_table "nodes_v6"
  end
end
