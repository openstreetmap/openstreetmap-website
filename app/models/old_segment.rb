class OldSegment < ActiveRecord::Base
  set_table_name 'segments'

  belongs_to :user

  def self.from_segment(segment)
    old_segment = OldSegment.new
    old_segment.node_a = segment.node_a
    old_segment.node_b = segment.node_b
    old_segment.visible = segment.visible
    old_segment.tags = segment.tags
    old_segment.timestamp = segment.timestamp
    old_segment.user_id = segment.user_id
    old_segment.id = segment.id
    return old_segment
  end

  def to_xml_node
    el1 = XML::Node.new 'segment'
    el1['id'] = self.id.to_s
    el1['from'] = self.node_a.to_s
    el1['to'] = self.node_b.to_s
    el1['user'] = self.user.display_name if self.user.data_public?
    Segment.split_tags(el1, self.tags)
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end
end
