require File.dirname(__FILE__) + '/../test_helper'

class ChangesetTagTest < Test::Unit::TestCase
  fixtures :changeset_tags
  
  
  def test_changeset_tags_count
    assert_equal 1, ChangesetTag.count
  end
  
end
