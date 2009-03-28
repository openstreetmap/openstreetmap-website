require File.dirname(__FILE__) + '/../test_helper'

class ChangesetTest < Test::Unit::TestCase
  api_fixtures
  
  def test_changeset_count
    assert_equal 6, Changeset.count
  end
  
end
