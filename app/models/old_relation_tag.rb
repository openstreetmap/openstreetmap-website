class OldRelationTag < ActiveRecord::Base
  self.table_name = "relation_tags"
  self.primary_keys = "relation_id", "version", "k"

  belongs_to :old_relation, :foreign_key => [:relation_id, :version]

  validates :old_relation, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => [:relation_id, :version] }
end
