class WaySegment < ActiveRecord::Base
  set_table_name 'current_way_segments'

  belongs_to :segment
end
