class WayNode < ActiveRecord::Base
  set_table_name 'current_way_nodes'

  belongs_to :node
end
