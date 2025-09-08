# frozen_string_literal: true

require "test_helper"

class ChangesetTest < ActiveSupport::TestCase
  def test_num_changes_valid
    changeset = create(:changeset)
    assert_predicate changeset, :valid?
    changeset.num_changes = nil
    assert_not_predicate changeset, :valid?
    changeset.num_changes = -1
    assert_not_predicate changeset, :valid?
    changeset.num_changes = 0
    assert_predicate changeset, :valid?
    changeset.num_changes = 1
    assert_predicate changeset, :valid?
  end

  def test_num_type_changes_valid
    [:num_created_nodes, :num_modified_nodes, :num_deleted_nodes,
     :num_created_ways, :num_modified_ways, :num_deleted_ways,
     :num_created_relations, :num_modified_relations, :num_deleted_relations].each do |counter_attribute|
       changeset = create(:changeset)
       assert_predicate changeset, :valid?
       changeset[counter_attribute] = nil
       assert_not_predicate changeset, :valid?
       changeset[counter_attribute] = -1
       assert_not_predicate changeset, :valid?
       changeset[counter_attribute] = 0
       assert_predicate changeset, :valid?
       changeset[counter_attribute] = 1
       assert_predicate changeset, :valid?
     end
  end

  def test_num_type_changes_in_sync_for_new_changeset
    changeset = create(:changeset)

    assert_equal 0, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_not_in_sync_for_changeset_without_type_changes
    changeset = create(:changeset, :num_changes => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_not_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_created_nodes
    changeset = create(:changeset, :num_changes => 1, :num_created_nodes => 1)

    assert_equal 1, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 1, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_modified_nodes
    changeset = create(:changeset, :num_changes => 1, :num_modified_nodes => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 1, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 1, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_deleted_nodes
    changeset = create(:changeset, :num_changes => 1, :num_deleted_nodes => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 1, changeset.num_deleted_elements

    assert_equal 1, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_changed_nodes
    changeset = create(:changeset, :num_changes => 3 + 2 + 1,
                                   :num_created_nodes => 3,
                                   :num_modified_nodes => 2,
                                   :num_deleted_nodes => 1)

    assert_equal 3, changeset.num_created_elements
    assert_equal 2, changeset.num_modified_elements
    assert_equal 1, changeset.num_deleted_elements

    assert_equal 3 + 2 + 1, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_created_ways
    changeset = create(:changeset, :num_changes => 1, :num_created_ways => 1)

    assert_equal 1, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 1, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_modified_ways
    changeset = create(:changeset, :num_changes => 1, :num_modified_ways => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 1, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 1, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_deleted_ways
    changeset = create(:changeset, :num_changes => 1, :num_deleted_ways => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 1, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 1, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_changed_ways
    changeset = create(:changeset, :num_changes => 3 + 2 + 1,
                                   :num_created_ways => 3,
                                   :num_modified_ways => 2,
                                   :num_deleted_ways => 1)

    assert_equal 3, changeset.num_created_elements
    assert_equal 2, changeset.num_modified_elements
    assert_equal 1, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 3 + 2 + 1, changeset.num_changed_ways
    assert_equal 0, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_created_relations
    changeset = create(:changeset, :num_changes => 1, :num_created_relations => 1)

    assert_equal 1, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_modified_relations
    changeset = create(:changeset, :num_changes => 1, :num_modified_relations => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 1, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_deleted_relations
    changeset = create(:changeset, :num_changes => 1, :num_deleted_relations => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 1, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_changed_relations
    changeset = create(:changeset, :num_changes => 3 + 2 + 1,
                                   :num_created_relations => 3,
                                   :num_modified_relations => 2,
                                   :num_deleted_relations => 1)

    assert_equal 3, changeset.num_created_elements
    assert_equal 2, changeset.num_modified_elements
    assert_equal 1, changeset.num_deleted_elements

    assert_equal 0, changeset.num_changed_nodes
    assert_equal 0, changeset.num_changed_ways
    assert_equal 3 + 2 + 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_created_elements
    changeset = create(:changeset, :num_changes => 3 + 2 + 1,
                                   :num_created_nodes => 3,
                                   :num_created_ways => 2,
                                   :num_created_relations => 1)

    assert_equal 3 + 2 + 1, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 3, changeset.num_changed_nodes
    assert_equal 2, changeset.num_changed_ways
    assert_equal 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_modified_elements
    changeset = create(:changeset, :num_changes => 3 + 2 + 1,
                                   :num_modified_nodes => 3,
                                   :num_modified_ways => 2,
                                   :num_modified_relations => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 3 + 2 + 1, changeset.num_modified_elements
    assert_equal 0, changeset.num_deleted_elements

    assert_equal 3, changeset.num_changed_nodes
    assert_equal 2, changeset.num_changed_ways
    assert_equal 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_deleted_elements
    changeset = create(:changeset, :num_changes => 3 + 2 + 1,
                                   :num_deleted_nodes => 3,
                                   :num_deleted_ways => 2,
                                   :num_deleted_relations => 1)

    assert_equal 0, changeset.num_created_elements
    assert_equal 0, changeset.num_modified_elements
    assert_equal 3 + 2 + 1, changeset.num_deleted_elements

    assert_equal 3, changeset.num_changed_nodes
    assert_equal 2, changeset.num_changed_ways
    assert_equal 1, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_num_type_changes_in_sync_for_changeset_with_changed_elements
    changeset = create(:changeset, :num_changes => 33 + 32 + 31 + 23 + 22 + 21 + 13 + 12 + 11,
                                   :num_created_nodes => 33,
                                   :num_created_ways => 32,
                                   :num_created_relations => 31,
                                   :num_modified_nodes => 23,
                                   :num_modified_ways => 22,
                                   :num_modified_relations => 21,
                                   :num_deleted_nodes => 13,
                                   :num_deleted_ways => 12,
                                   :num_deleted_relations => 11)

    assert_equal 33 + 32 + 31, changeset.num_created_elements
    assert_equal 23 + 22 + 21, changeset.num_modified_elements
    assert_equal 13 + 12 + 11, changeset.num_deleted_elements

    assert_equal 33 + 23 + 13, changeset.num_changed_nodes
    assert_equal 32 + 22 + 12, changeset.num_changed_ways
    assert_equal 31 + 21 + 11, changeset.num_changed_relations

    assert_predicate changeset, :num_type_changes_in_sync?
  end

  def test_actual_num_changed_elements_in_sync
    changeset = create(:changeset, :num_changes => 5 + 4 + 3,
                                   :num_created_nodes => 5,
                                   :num_created_ways => 4,
                                   :num_created_relations => 3)
    create_list(:old_node, 5, :changeset => changeset)
    create_list(:old_way, 4, :changeset => changeset)
    create_list(:old_relation, 3, :changeset => changeset)

    assert_predicate changeset, :num_type_changes_in_sync?

    assert_equal 5, changeset.actual_num_changed_nodes
    assert_equal 4, changeset.actual_num_changed_ways
    assert_equal 3, changeset.actual_num_changed_relations
  end

  def test_actual_num_changed_elements_out_of_sync
    changeset = create(:changeset, :num_changes => 5 + 4 + 3)
    create_list(:old_node, 5, :changeset => changeset)
    create_list(:old_way, 4, :changeset => changeset)
    create_list(:old_relation, 3, :changeset => changeset)

    assert_not_predicate changeset, :num_type_changes_in_sync?

    assert_equal 5, changeset.actual_num_changed_nodes
    assert_equal 4, changeset.actual_num_changed_ways
    assert_equal 3, changeset.actual_num_changed_relations
  end

  def test_from_xml_no_text
    no_text = ""
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_text, :create => true)
    end
    assert_match(/Must specify a string with one or more characters/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_text, :create => false)
    end
    assert_match(/Must specify a string with one or more characters/, message_update.message)
  end

  def test_from_xml_no_changeset
    nocs = "<osm></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nocs, :create => true)
    end
    assert_match %r{XML doesn't contain an osm/changeset element}, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nocs, :create => false)
    end
    assert_match %r{XML doesn't contain an osm/changeset element}, message_update.message
  end

  def test_from_xml_no_k_v
    nokv = "<osm><changeset><tag /></changeset></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nokv, :create => true)
    end
    assert_match(/tag is missing key/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nokv, :create => false)
    end
    assert_match(/tag is missing key/, message_update.message)
  end

  def test_from_xml_no_v
    no_v = "<osm><changeset><tag k='key' /></changeset></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_v, :create => true)
    end
    assert_match(/tag is missing value/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_v, :create => false)
    end
    assert_match(/tag is missing value/, message_update.message)
  end

  def test_from_xml_duplicate_k
    dupk = "<osm><changeset><tag k='dup' v='test' /><tag k='dup' v='value' /></changeset></osm>"
    message_create = assert_raise(OSM::APIDuplicateTagsError) do
      Changeset.from_xml(dupk, :create => true)
    end
    assert_equal "Element changeset/ has duplicate tags with key dup", message_create.message
    message_update = assert_raise(OSM::APIDuplicateTagsError) do
      Changeset.from_xml(dupk, :create => false)
    end
    assert_equal "Element changeset/ has duplicate tags with key dup", message_update.message
  end

  def test_from_xml_valid
    # Example taken from the Update section on the API_v0.6 docs on the wiki
    xml = "<osm><changeset><tag k=\"comment\" v=\"Just adding some streetnames and a restaurant\"/></changeset></osm>"
    assert_nothing_raised do
      Changeset.from_xml(xml, :create => false)
    end
    assert_nothing_raised do
      Changeset.from_xml(xml, :create => true)
    end
  end
end
