class WayTag < ActiveRecord::Base
  set_table_name 'current_way_tags'
  set_primary_keys :way_id, :k

  belongs_to :way
  
  validates_presence_of :way
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => :way_id
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
