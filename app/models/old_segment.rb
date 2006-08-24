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

end
