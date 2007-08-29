class OldWayNode < ActiveRecord::Base
  belongs_to :user

  set_table_name 'way_nodes'

end
