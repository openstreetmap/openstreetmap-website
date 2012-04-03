require File.dirname(__FILE__) + '/../test_helper'
require 'osm'

class RedactionTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :redactions

  def test_cannot_redact_current
    n = current_nodes(:node_with_versions)
    r = redactions(:example)
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      n.redact!(r)
    end
  end

  def test_cannot_redact_current_via_old
    n = nodes(:node_with_versions_v4)
    r = redactions(:example)
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      n.redact!(r)
    end
  end

  def test_can_redact_old
    n = nodes(:node_with_versions_v3)
    r = redactions(:example)
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    assert_nothing_raised(OSM::APICannotRedactError) do
      n.redact!(r)
    end
    assert_equal(true, n.redacted?, "Expected node to be redacted after redact! call.")
  end

end
