class WayTag < ActiveRecord::Base
  self.table_name = "current_way_tags"
  self.primary_keys = "way_id", "k"

  belongs_to :way

  validates :way, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => :way_id }
end
