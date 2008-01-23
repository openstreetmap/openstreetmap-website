class CreateOldNodeTags < ActiveRecord::Migration
  def self.up
    create_table "node_tags", myisam_table do |t|
      t.column "id",      :bigint,  :limit => 64, :default => 0, :null => false
      t.column "sequence_id", :bigint, :limit => 11
      t.column "k",       :string
      t.column "v",       :string
      t.column "version", :bigint,  :limit => 20
    end

    add_index "node_tags", ["version"], :name => "node_tags_id_version_idx"
    add_primary_key "node_tags", ["id", "version", "sequence_id"]

  end

  def self.down
    drop_table :node_tags
  end
end
