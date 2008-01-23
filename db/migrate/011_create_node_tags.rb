class CreateNodeTags < ActiveRecord::Migration
  def self.up
    create_table "current_node_tags", myisam_table do |t|
      t.column "id", :bigint, :limit => 64
      t.column "sequence_id", :bigint, :limit => 11
      t.column "k",  :string,                :default => "", :null => false
      t.column "v",  :string,                :default => "", :null => false
    end

    add_index "current_node_tags", ["id"], :name => "current_node_tags_id_idx"
    add_primary_key "current_node_tags", ["sequence_id", "id"]
       
    execute "CREATE FULLTEXT INDEX `current_node_tags_v_idx` ON `current_node_tags` (`v`)"


  end

  def self.down
    drop_table :current_node_tags
  end
end
