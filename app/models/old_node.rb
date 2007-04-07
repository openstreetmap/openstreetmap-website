class OldNode < ActiveRecord::Base
  set_table_name 'nodes'

  belongs_to :user

  def self.from_node(node)
    old_node = OldNode.new
    old_node.latitude = node.latitude
    old_node.longitude = node.longitude
    old_node.visible = node.visible
    old_node.tags = node.tags
    old_node.timestamp = node.timestamp
    old_node.user_id = node.user_id
    old_node.id = node.id
    return old_node
  end

  def to_xml_node
    el1 = XML::Node.new 'node'
    el1['id'] = self.id.to_s
    el1['lat'] = self.latitude.to_s
    el1['lon'] = self.longitude.to_s
    el1['user'] = self.user.display_name if self.user.data_public?
    Node.split_tags(el1, self.tags)
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end

end
