class WayTag < ActiveRecord::Base
  set_table_name 'current_way_tags'

  # False multipart keys. The following would be a hack:
  # set_primary_keys :id, :k, :v
  # FIXME add a real multipart key to waytags so that we can do eager loadin

  belongs_to :way, :foreign_key => 'id'
  
  validates_presence_of :id
  validates_length_of :k, :v, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :id, :scope => :k
  validates_numericality_of :id, :only_integer => true
end
