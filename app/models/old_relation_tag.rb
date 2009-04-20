class OldRelationTag < ActiveRecord::Base
  set_table_name 'relation_tags'
  
  belongs_to :old_relation, :foreign_key => [:id, :version]
  
  validates_presence_of :id, :version
  validates_length_of :k, :v, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :id, :scope => [:k, :version]
  validates_numericality_of :id, :version, :only_integer => true
end
