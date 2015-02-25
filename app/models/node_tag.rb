class NodeTag < ActiveRecord::Base
  self.table_name = "current_node_tags"
  self.primary_keys = "node_id", "k"

  belongs_to :node

  validates :node, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => :node_id }
end
