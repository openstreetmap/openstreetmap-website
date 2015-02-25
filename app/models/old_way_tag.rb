class OldWayTag < ActiveRecord::Base
  self.table_name = "way_tags"
  self.primary_keys = "way_id", "version", "k"

  belongs_to :old_way, :foreign_key => [:way_id, :version]

  validates :old_way, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => [:way_id, :version] }
end
