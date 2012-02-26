class WayNode < ActiveRecord::Base
  self.table_name = "current_way_nodes"
  self.primary_keys = "way_id", "sequence_id"

  belongs_to :way
  belongs_to :node
end
