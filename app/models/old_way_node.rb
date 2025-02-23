# == Schema Information
#
# Table name: way_nodes
#
#  way_id      :bigint           not null, primary key
#  node_id     :bigint           not null
#  version     :bigint           not null, primary key
#  sequence_id :bigint           not null, primary key
#
# Indexes
#
#  way_nodes_node_idx  (node_id)
#
# Foreign Keys
#
#  way_nodes_id_fkey  ([way_id, version] => ways[way_id, version])
#

class OldWayNode < ApplicationRecord
  self.table_name = "way_nodes"

  belongs_to :old_way, :foreign_key => [:way_id, :version], :inverse_of => :old_nodes
  # A bit messy, referring to current nodes and ways, should do for the data browser for now
  belongs_to :node
  belongs_to :way
end
