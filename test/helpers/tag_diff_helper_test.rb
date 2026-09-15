# frozen_string_literal: true

require "test_helper"

class TagDiffHelperTest < ActionView::TestCase
  def test_tag_diff
    old_tags = { "highway" => "trunk", "maxspeed" => "50", "ref" => "A1" }
    new_tags = { "highway" => "tertiary", "name" => "Main St", "ref" => "A1" }

    diffs = tag_diff(new_tags, old_tags)

    assert_equal 3, diffs.length

    assert_equal "highway", diffs[0][:key]
    assert_equal "modified", diffs[0][:type]
    assert_equal "trunk", diffs[0][:old_value]
    assert_equal "tertiary", diffs[0][:new_value]

    assert_equal "maxspeed", diffs[1][:key]
    assert_equal "removed", diffs[1][:type]
    assert_equal "50", diffs[1][:old_value]

    assert_equal "name", diffs[2][:key]
    assert_equal "added", diffs[2][:type]
    assert_equal "Main St", diffs[2][:new_value]

    assert_nil(diffs.find { |d| d[:key] == "ref" })
  end
end
