class OldNode < ActiveRecord::Base
  set_table_name 'nodes'

  belongs_to :user

  def self.from_node(node)
    old_node = OldNode.new
    old_node.latitude = node.latitude
    old_node.longitude = node.longitude
    old_node.visible = 1
    old_node.tags = node.tags
    old_node.timestamp = node.timestamp
    old_node.user_id = node.user_id
    old_node.id = node.id
    return old_node
  end



end
