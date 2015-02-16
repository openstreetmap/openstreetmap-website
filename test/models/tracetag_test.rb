require 'test_helper'

class TracetagTest < ActiveSupport::TestCase
  api_fixtures

  def test_tracetag_count
    assert_equal 4, Tracetag.count
  end

  def test_validations
    tracetag_valid({})
    tracetag_valid({ :tag => nil }, false)
    tracetag_valid({ :tag => '' }, false)
    tracetag_valid(:tag => 'a')
    tracetag_valid(:tag => 'a' * 255)
    tracetag_valid({ :tag => 'a' * 256 }, false)
    tracetag_valid({ :tag => 'a/b' }, false)
    tracetag_valid({ :tag => 'a;b' }, false)
    tracetag_valid({ :tag => 'a.b' }, false)
    tracetag_valid({ :tag => 'a,b' }, false)
    tracetag_valid({ :tag => 'a?b' }, false)
  end

  private

  def tracetag_valid(attrs, result = true)
    entry = Tracetag.new(gpx_file_tags(:first_trace_1).attributes)
    entry.assign_attributes(attrs)
    assert_equal result, entry.valid?, "Expected #{attrs.inspect} to be #{result}"
  end
end
