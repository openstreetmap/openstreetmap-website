class NodeTag < ActiveRecord::Base
  set_table_name 'current_node_tags'

  belongs_to :node, :foreign_key => 'id'
  
  validates_presence_of :id
  validates_length_of :k, :v, :maximum => 255, :allow_blank => true
end
