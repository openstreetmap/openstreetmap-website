# == Schema Information
#
# Table name: current_way_nodes
#
#  way_id      :integer          not null, primary key
#  node_id     :integer          not null
#  sequence_id :integer          not null, primary key
#
# Indexes
#
#  current_way_nodes_node_idx  (node_id)
#
# Foreign Keys
#
#  current_way_nodes_id_fkey       (way_id => current_ways.id)
#  current_way_nodes_node_id_fkey  (node_id => current_nodes.id)
#

class WayNode < ActiveRecord::Base
  self.table_name = "current_way_nodes"
  self.primary_keys = "way_id", "sequence_id"

  belongs_to :way
  belongs_to :node
end
