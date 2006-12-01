class Tracepoint < ActiveRecord::Base
  set_table_name 'gps_points'

#  validates_numericality_of :latitude
#  validates_numericality_of :longitude

  belongs_to :user
  belongs_to :trace, :foreign_key => 'gpx_id'
end
