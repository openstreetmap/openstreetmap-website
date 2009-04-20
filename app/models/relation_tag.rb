class RelationTag < ActiveRecord::Base
  set_table_name 'current_relation_tags'

  belongs_to :relation, :foreign_key => 'id'

  validates_presence_of :id
  validates_length_of :k, :v, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :id, :scope => :k
  validates_numericality_of :id, :only_integer => true
end
