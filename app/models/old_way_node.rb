class OldWayNode < ActiveRecord::Base
  set_table_name 'way_nodes'
  set_primary_keys :way_id, :version, :sequence_id

  belongs_to :old_way, :foreign_key => [:way_id, :version]
  # A bit messy, referring to current nodes and ways, should do for the data browser for now
  belongs_to :node
  belongs_to :way
end
