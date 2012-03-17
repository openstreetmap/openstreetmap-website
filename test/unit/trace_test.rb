require File.dirname(__FILE__) + '/../test_helper'

class TraceTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_trace_count
    assert_equal 5, Trace.count
  end

  def test_visible
    check_query(Trace.visible, :public_trace_file, :anon_trace_file, :trackable_trace_file, :identifiable_trace_file)
  end

  def test_visible_to
    check_query(Trace.visible_to(1), :public_trace_file, :identifiable_trace_file)
    check_query(Trace.visible_to(2), :public_trace_file, :anon_trace_file, :trackable_trace_file, :identifiable_trace_file)
    check_query(Trace.visible_to(3), :public_trace_file, :identifiable_trace_file)
  end

  def test_public
    check_query(Trace.public, :public_trace_file, :identifiable_trace_file, :deleted_trace_file)
  end

  def test_validations
    trace_valid({})
    trace_valid({:user_id => nil}, false)
    trace_valid({:name => 'a'*255})
    trace_valid({:name => 'a'*256}, false)
    trace_valid({:description => nil}, false)
    trace_valid({:description => 'a'*255})
    trace_valid({:description => 'a'*256}, false)
    trace_valid({:visibility => "private"})
    trace_valid({:visibility => "public"})
    trace_valid({:visibility => "trackable"})
    trace_valid({:visibility => "identifiable"})
    trace_valid({:visibility => "foo"}, false)
  end

  def test_tagstring
    trace = Trace.new
    trace.tagstring = "foo bar baz"
    assert_equal 3, trace.tags.length
    assert_equal "foo", trace.tags[0].tag
    assert_equal "bar", trace.tags[1].tag
    assert_equal "baz", trace.tags[2].tag
    assert_equal "foo, bar, baz", trace.tagstring
    trace.tagstring = "foo, bar baz ,qux"
    assert_equal 3, trace.tags.length
    assert_equal "foo", trace.tags[0].tag
    assert_equal "bar baz", trace.tags[1].tag
    assert_equal "qux", trace.tags[2].tag
    assert_equal "foo, bar baz, qux", trace.tagstring
  end

  def test_public?
    assert_equal true, gpx_files(:public_trace_file).public?
    assert_equal false, gpx_files(:anon_trace_file).public?
    assert_equal false, gpx_files(:trackable_trace_file).public?
    assert_equal true, gpx_files(:identifiable_trace_file).public?
    assert_equal true, gpx_files(:deleted_trace_file).public?
  end

  def test_trackable?
    assert_equal false, gpx_files(:public_trace_file).trackable?
    assert_equal false, gpx_files(:anon_trace_file).trackable?
    assert_equal true, gpx_files(:trackable_trace_file).trackable?
    assert_equal true, gpx_files(:identifiable_trace_file).trackable?
    assert_equal false, gpx_files(:deleted_trace_file).trackable?
  end

  def test_identifiable?
    assert_equal false, gpx_files(:public_trace_file).identifiable?
    assert_equal false, gpx_files(:anon_trace_file).identifiable?
    assert_equal false, gpx_files(:trackable_trace_file).identifiable?
    assert_equal true, gpx_files(:identifiable_trace_file).identifiable?
    assert_equal false, gpx_files(:deleted_trace_file).identifiable?
  end

private

  def check_query(query, *traces)
    traces = traces.map { |t| gpx_files(t) }.sort
    assert_equal traces, query.order(:id)
  end

  def trace_valid(attrs, result = true)
    entry = Trace.new(gpx_files(:public_trace_file).attributes, :without_protection => true)
    entry.assign_attributes(attrs, :without_protection => true)
    assert_equal result, entry.valid?, "Expected #{attrs.inspect} to be #{result}"
  end
end
