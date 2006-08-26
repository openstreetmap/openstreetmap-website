class WayTag < ActiveRecord::Base
  set_table_name 'current_way_tags'

  belongs_to :way, :foreign_key => 'id'

end
