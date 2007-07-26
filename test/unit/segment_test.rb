require File.dirname(__FILE__) + '/../test_helper'

class SegmentTest < Test::Unit::TestCase
  fixtures :current_nodes, :nodes, :current_segments, :segments, :users
  set_fixture_class :current_segments => :Segment
  set_fixture_class :segments => :OldSegment
  set_fixture_class :current_nodes => :Node
  set_fixture_class :nodes => :OldNode

  def test_create

    segment_template = Segment.new(:node_a => nodes(:used_node_1).id,
                             :node_b => nodes(:used_node_2).id,
                             :user_id => users(:normal_user).id,
                             :visible => 1,
                             :tags => "")
    assert segment_template.save_with_history

    segment = Segment.find(segment_template.id)
    assert_not_nil segment
    assert_equal segment_template.node_a, segment.node_a
    assert_equal segment_template.node_b, segment.node_b
    assert_equal segment_template.user_id, segment.user_id
    assert_equal segment_template.visible, segment.visible
    assert_equal segment_template.tags, segment.tags
    assert_equal segment_template.timestamp.to_i, segment.timestamp.to_i

    assert_equal OldSegment.find(:all, :conditions => [ "id = ?", segment_template.id ]).length, 1
    old_segment = OldSegment.find(:first, :conditions => [ "id = ?", segment_template.id ])
    assert_not_nil old_segment
    assert_equal segment_template.node_a, old_segment.node_a
    assert_equal segment_template.node_b, old_segment.node_b
    assert_equal segment_template.user_id, old_segment.user_id
    assert_equal segment_template.visible, old_segment.visible
    assert_equal segment_template.tags, old_segment.tags
    assert_equal segment_template.timestamp.to_i, old_segment.timestamp.to_i
  end

  def test_update
    segment_template = Segment.find(1)
    assert_not_nil segment_template

    assert_equal OldSegment.find(:all, :conditions => [ "id = ?", segment_template.id ]).length, 1
    old_segment_template = OldSegment.find(:first, :conditions => [ "id = ?", segment_template.id ])
    assert_not_nil old_segment_template

    segment_template.node_a = nodes(:used_node_2).id
    segment_template.node_b = nodes(:used_node_1).id
    segment_template.tags = "updated=yes"
    assert segment_template.save_with_history

    segment = Segment.find(segment_template.id)
    assert_not_nil segment
    assert_equal segment_template.node_a, segment.node_a
    assert_equal segment_template.node_b, segment.node_b
    assert_equal segment_template.user_id, segment.user_id
    assert_equal segment_template.visible, segment.visible
    assert_equal segment_template.tags, segment.tags
    assert_equal segment_template.timestamp.to_i, segment.timestamp.to_i

    assert_equal OldSegment.find(:all, :conditions => [ "id = ?", segment_template.id ]).length, 2
    assert_equal OldSegment.find(:all, :conditions => [ "id = ? and timestamp = ?", segment_template.id, segment_template.timestamp ]).length, 1
    old_segment = OldSegment.find(:first, :conditions => [ "id = ? and timestamp = ?", segment_template.id, segment_template.timestamp ])
    assert_not_nil old_segment
    assert_equal segment_template.node_a, old_segment.node_a
    assert_equal segment_template.node_b, old_segment.node_b
    assert_equal segment_template.user_id, old_segment.user_id
    assert_equal segment_template.visible, old_segment.visible
    assert_equal segment_template.tags, old_segment.tags
    assert_equal segment_template.timestamp.to_i, old_segment.timestamp.to_i
  end

  def test_delete
    segment_template = Segment.find(1)
    assert_not_nil segment_template

    assert_equal OldSegment.find(:all, :conditions => [ "id = ?", segment_template.id ]).length, 1
    old_segment_template = OldSegment.find(:first, :conditions => [ "id = ?", segment_template.id ])
    assert_not_nil old_segment_template

    segment_template.visible = 0
    assert segment_template.save_with_history

    segment = Segment.find(segment_template.id)
    assert_not_nil segment
    assert_equal segment_template.node_a, segment.node_a
    assert_equal segment_template.node_b, segment.node_b
    assert_equal segment_template.user_id, segment.user_id
    assert_equal segment_template.visible, segment.visible
    assert_equal segment_template.tags, segment.tags
    assert_equal segment_template.timestamp.to_i, segment.timestamp.to_i

    assert_equal OldSegment.find(:all, :conditions => [ "id = ?", segment_template.id ]).length, 2
    assert_equal OldSegment.find(:all, :conditions => [ "id = ? and timestamp = ?", segment_template.id, segment_template.timestamp ]).length, 1
    old_segment = OldSegment.find(:first, :conditions => [ "id = ? and timestamp = ?", segment_template.id, segment_template.timestamp ])
    assert_not_nil old_segment
    assert_equal segment_template.node_a, old_segment.node_a
    assert_equal segment_template.node_b, old_segment.node_b
    assert_equal segment_template.user_id, old_segment.user_id
    assert_equal segment_template.visible, old_segment.visible
    assert_equal segment_template.tags, old_segment.tags
    assert_equal segment_template.timestamp.to_i, old_segment.timestamp.to_i
  end
end
