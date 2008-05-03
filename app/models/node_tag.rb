class NodeTag < ActiveRecord::Base
  set_table_name 'current_node_tags'

  belongs_to :node, :foreign_key => 'id'
end
