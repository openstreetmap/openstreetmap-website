class CreateTempOldNodes < ActiveRecord::Migration
  def self.up
    create_table "temp_nodes", myisam_table do |t|
      t.column "id",        :bigint,  :limit => 64, :null => false
      t.column "version",   :bigint,  :limit => 20, :null => false
      t.column "latitude",  :double,                :null => false
      t.column "longitude", :double,                :null => false
      t.column "user_id",   :bigint,  :limit => 20, :null => false
      t.column "visible",   :boolean,               :null => false
      t.column "timestamp", :datetime,              :null => false
      t.column "tile",      :integer,               :null => false
    end

    add_primary_key "temp_nodes", ["id", "version"] 
    add_index "temp_nodes", ["timestamp"], :name => "temp_nodes_timestamp_idx"
    add_index "temp_nodes", ["tile"], :name => "temp_nodes_tile_idx"

    change_column "temp_nodes", "version", :bigint, :limit => 20, :null => false, :options => "AUTO_INCREMENT"
  end

  def self.down
    drop_table :temp_nodes
  end
end
