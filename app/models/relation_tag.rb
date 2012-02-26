class RelationTag < ActiveRecord::Base
  self.table_name = "current_relation_tags"
  self.primary_keys = "relation_id", "k"

  belongs_to :relation

  validates_presence_of :relation
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => :relation_id
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
