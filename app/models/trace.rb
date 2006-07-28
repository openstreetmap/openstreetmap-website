class Trace < ActiveRecord::Base
  set_table_name 'gpx_files'
  has_many :trace_points, :foreign_key => 'gpx_id'
end
