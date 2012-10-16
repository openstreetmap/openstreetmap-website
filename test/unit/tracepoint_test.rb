# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

class TracepointTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_tracepoint_count
    assert_equal 4, Tracepoint.count
  end
  
end
