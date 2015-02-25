class RelationTag < ActiveRecord::Base
  self.table_name = "current_relation_tags"
  self.primary_keys = "relation_id", "k"

  belongs_to :relation

  validates :relation, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => :relation_id }
end
