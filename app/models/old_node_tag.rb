class OldNodeTag < ActiveRecord::Base
  self.table_name = "node_tags"
  self.primary_keys = "node_id", "version", "k"

  belongs_to :old_node, :foreign_key => [:node_id, :version]

  validates :old_node, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => [:node_id, :version] }
end
