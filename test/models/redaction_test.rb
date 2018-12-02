require "test_helper"
require "osm"

class RedactionTest < ActiveSupport::TestCase
  # should not redact a node that is current
  def test_cannot_redact_current
    n = create(:node)
    r = create(:redaction)
    # checks if node n is redacted and expects false
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    # should raise OSM::APICannotRedactError, if current
    assert_raise(OSM::APICannotRedactError) do
      # gets if node is not current version
      n.redact!(r)
    end
  end

  # node with older versions in history should not be redactable
  def test_cannot_redact_current_via_old
    node = create(:node, :with_history)
    # older nodes of version 1 taken from node with history
    node_v1 = node.old_nodes.find_by(:version => 1)
    r = create(:redaction)
    # node_v1 should not be redacted
    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      # checks if node is current and should raise OSM::APICannotRedactError if it is
      node_v1.redact!(r)
    end
  end

  # should not be able to do redactions with nodes of version 2
  def test_can_redact_old
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    r = create(:redaction)
    # node_v1 should not be redacted
    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    # will not do anything if node_v1 is not current and error is raised
    assert_nothing_raised do
      node_v1.redact!(r)
    end
    # checks if node_v1 is redacted but if node_v2 is not redacted
    assert_equal(true, node_v1.redacted?, "Expected node version 1 to be redacted after redact! call.")
    assert_equal(false, node_v2.redacted?, "Expected node version 2 to not be redacted after redact! call.")
  end

  # redaction with blank title should be invalid
  def test_redaction_cannot_have_empty_title
    redaction = create(:redaction)
    redaction.title = ""
    redaction.description = "Some description."
    assert_not redaction.save
    assert redaction.errors[:title].include?("can't be blank")
  end

  # redaction with spaces for title should be invalid
  def test_redaction_cannot_have_title_with_only_spaces
    redaction = create(:redaction)
    redaction.title = "    "
    redaction.description = "Some description."
    assert_not redaction.save
    assert redaction.errors[:title].include?("can't be blank")
  end

  # redaction with blank description should be invalid
  def test_redaction_cannot_have_empty_description
    redaction = create(:redaction)
    redaction.title = "Some title."
    redaction.description = ""
    assert_not redaction.save
    assert redaction.errors[:description].include?("can't be blank")
  end

  # redaction with blank description should be invalid
  def test_redaction_cannot_have_description_with_only_spaces
    redaction = create(:redaction)
    redaction.title = "Some title."
    redaction.description = "    "
    assert_not redaction.save
    assert redaction.errors[:description].include?("can't be blank")
  end
end
