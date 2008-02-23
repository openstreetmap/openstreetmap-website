class CreateOldNodeTags < ActiveRecord::Migration
  def self.up
    create_table "node_tags", myisam_table do |t|
      t.column "id",          :bigint, :limit => 64, :default => 0, :null => false
      t.column "version",     :bigint, :limit => 20,                :null => false
      t.column "sequence_id", :bigint, :limit => 11,                :null => false
      t.column "k",           :string,                              :null => false
      t.column "v",           :string,                              :null => false
    end

    add_primary_key "node_tags", ["id", "version", "sequence_id"]
  end

  def self.down
    drop_table :node_tags
  end
end
