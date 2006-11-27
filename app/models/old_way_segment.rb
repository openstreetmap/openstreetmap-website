class OldWaySegment < ActiveRecord::Base
  belongs_to :user

  set_table_name 'way_segments'

end
