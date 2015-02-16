class OldRelationTag < ActiveRecord::Base
  self.table_name = "relation_tags"
  self.primary_keys = "relation_id", "version", "k"

  belongs_to :old_relation, :foreign_key => [:relation_id, :version]

  validates_presence_of :old_relation
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => [:relation_id, :version]
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
