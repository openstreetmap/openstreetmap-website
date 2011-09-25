class OldWayTag < ActiveRecord::Base
  set_table_name 'way_tags'
  set_primary_keys :way_id, :version, :k

  belongs_to :old_way, :foreign_key => [:way_id, :version]

  validates_presence_of :old_way
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => [:way_id, :version]
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
