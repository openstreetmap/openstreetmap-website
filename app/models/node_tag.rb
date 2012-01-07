class NodeTag < ActiveRecord::Base
  set_table_name 'current_node_tags'
  set_primary_keys :node_id, :k

  belongs_to :node
  
  validates_presence_of :node
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => :node_id
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
