require "test_helper"
require "osm"

class RedactionTest < ActiveSupport::TestCase
  def test_cannot_redact_current
    n = create(:node)
    r = create(:redaction)
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      n.redact!(r)
    end
  end

  def test_cannot_redact_current_via_old
    node = create(:node)
    node_v1 = create(:old_node, :node_id => node.id)
    r = create(:redaction)
    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      node_v1.redact!(r)
    end
  end

  def test_can_redact_old
    node = create(:node, :version => 2)
    node_v1 = create(:old_node, :node_id => node.id)
    node_v2 = create(:old_node, :node_id => node.id, :version => 2)
    r = create(:redaction)

    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    assert_nothing_raised(OSM::APICannotRedactError) do
      node_v1.redact!(r)
    end
    assert_equal(true, node_v1.redacted?, "Expected node version 1 to be redacted after redact! call.")
    assert_equal(false, node_v2.redacted?, "Expected node version 2 to not be redacted after redact! call.")
  end
end
