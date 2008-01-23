class AddVersionToNodes < ActiveRecord::Migration
  def self.up
    add_column :nodes, :version, :bigint, :limit => 20, :default => 0, :null => false
  end

  def self.down
    remove_column :nodes, :version
    add_index "nodes", ["id"], :name => "nodes_uid_idx"
  end
end
