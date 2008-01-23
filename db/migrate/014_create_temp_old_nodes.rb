class CreateTempOldNodes < ActiveRecord::Migration
  def self.up

    create_table "temp_nodes", myisam_table do |t|
      t.column "id",        :bigint,  :limit => 64
      t.column "version",    :bigint, :limit => 20, :default => 0, :null => false
      t.column "latitude",  :double
      t.column "longitude", :double
      t.column "user_id",   :bigint,  :limit => 20
      t.column "visible",   :boolean
      t.column "timestamp", :datetime
      t.column "tile", :integer, :null => false
    end

  add_primary_key "temp_nodes", ["id", "version"] 
  add_index "temp_nodes", ["timestamp"], :name => "temp_nodes_timestamp_idx"
  add_index "temp_nodes", ["tile"], :name => "temp_nodes_tile_idx"

  end

  def self.down
    drop_table :temp_nodes
  end
end
