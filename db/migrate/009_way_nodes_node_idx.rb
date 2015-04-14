class WayNodesNodeIdx < ActiveRecord::Migration
  def self.up
    add_index "way_nodes", ["node_id"], :name => "way_nodes_node_idx"
  end

  def self.down
    remove_index "way_nodes", :name => "way_nodes_node_idx"
  end
end
