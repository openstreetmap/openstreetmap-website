class OldNodeTag < ActiveRecord::Base
  self.table_name = "node_tags"
  self.primary_keys = "node_id", "version", "k"

  belongs_to :old_node, :foreign_key => [:node_id, :version]

  validates_presence_of :old_node
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => [:node_id, :version]
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
