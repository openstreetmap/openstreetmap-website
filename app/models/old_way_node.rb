# == Schema Information
#
# Table name: way_nodes
#
#  way_id      :bigint(8)        not null, primary key
#  node_id     :bigint(8)        not null
#  version     :bigint(8)        not null, primary key
#  sequence_id :bigint(8)        not null, primary key
#
# Indexes
#
#  way_nodes_node_idx  (node_id)
#
# Foreign Keys
#
#  way_nodes_id_fkey  (way_id => ways.way_id)
#

class OldWayNode < ActiveRecord::Base
  self.table_name = "way_nodes"
  self.primary_keys = "way_id", "version", "sequence_id"

  belongs_to :old_way, :foreign_key => [:way_id, :version]
  # A bit messy, referring to current nodes and ways, should do for the data browser for now
  belongs_to :node
  belongs_to :way
end
