class OldWayNode < ActiveRecord::Base
  set_table_name 'way_nodes'

  set_primary_keys :id, :version, :sequence_id

  belongs_to :way, :foreign_key=> :id
  
  # A bit messy, referring to current nodes, should do for the data browser for now
  belongs_to :node
end
