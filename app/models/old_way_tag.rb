class OldWayTag < ActiveRecord::Base
  belongs_to :user

  set_table_name 'way_tags'

  validates_presence_of :id
  validates_length_of :k, :v, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :id, :scope => [:k, :version]
  validates_numericality_of :id, :version, :only_integer => true
end
