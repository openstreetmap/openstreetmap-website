class OldWayTag < ActiveRecord::Base
  belongs_to :user

  set_table_name 'way_tags'

end
