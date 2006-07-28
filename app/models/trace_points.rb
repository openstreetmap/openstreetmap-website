class TracePoints < ActiveRecord::Base
  set_table_name 'gps_points'
  belongs_to :trace, :foreign_key => 'gpx_id'
end
