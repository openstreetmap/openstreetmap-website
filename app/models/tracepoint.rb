class Tracepoint < ActiveRecord::Base
set_table_name 'gps_points'

#  validates_numericality_of :latitude
#  validates_numericality_of :longitude

  belongs_to :user
  belongs_to :trace, :foreign_key => 'gpx_id'

  def lat=(l)
    self.latitude = l * 1000000
  end

  def lng=(l)
    self.longitude = l * 1000000
  end

  def lat
    return self.latitude.to_f / 1000000
  end

  def lon
    return self.longitude.to_f / 1000000
  end
end
