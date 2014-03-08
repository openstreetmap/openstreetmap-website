require 'test_helper'

class RelationTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_relation_count
    assert_equal 8, Relation.count
  end
  
  def test_from_xml_no_id
    noid = "<osm><relation version='12' changeset='23' /></osm>"
    assert_nothing_raised(OSM::APIBadXMLError) {
      Relation.from_xml(noid, true)
    }
    message = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(noid, false)
    }
    assert_match /ID is required when updating/, message.message
  end
  
  def test_from_xml_no_changeset_id
    nocs = "<osm><relation id='123' version='12' /></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(nocs, true)
    }
    assert_match /Changeset id is missing/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(nocs, false)
    }
    assert_match /Changeset id is missing/, message_update.message
  end
  
  def test_from_xml_no_version
    no_version = "<osm><relation id='123' changeset='23' /></osm>"
    assert_nothing_raised(OSM::APIBadXMLError) {
      Relation.from_xml(no_version, true)
    }
    message_update = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(no_version, false)
    }
    assert_match /Version is required when updating/, message_update.message
  end
  
  def test_from_xml_id_zero
    id_list = ["", "0", "00", "0.0", "a"]
    id_list.each do |id|
      zero_id = "<osm><relation id='#{id}' changeset='332' version='23' /></osm>"
      assert_nothing_raised(OSM::APIBadUserInput) {
        Relation.from_xml(zero_id, true)
      }
      message_update = assert_raise(OSM::APIBadUserInput) {
        Relation.from_xml(zero_id, false)
      }
      assert_match /ID of relation cannot be zero when updating/, message_update.message
    end
  end
  
  def test_from_xml_no_text
    no_text = ""
    message_create = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(no_text, true)
    }
    assert_match /Must specify a string with one or more characters/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(no_text, false)
    }
    assert_match /Must specify a string with one or more characters/, message_update.message
  end
  
  def test_from_xml_no_k_v
    nokv = "<osm><relation id='23' changeset='23' version='23'><tag /></relation></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(nokv, true)
    }
    assert_match /tag is missing key/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(nokv, false)
    }
    assert_match /tag is missing key/, message_update.message
  end
  
  def test_from_xml_no_v
    no_v = "<osm><relation id='23' changeset='23' version='23'><tag k='key' /></relation></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(no_v, true)
    }
    assert_match /tag is missing value/, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) {
      Relation.from_xml(no_v, false)
    }
    assert_match /tag is missing value/, message_update.message
  end
  
  def test_from_xml_duplicate_k
    dupk = "<osm><relation id='23' changeset='23' version='23'><tag k='dup' v='test'/><tag k='dup' v='tester'/></relation></osm>"
    message_create = assert_raise(OSM::APIDuplicateTagsError) {
      Relation.from_xml(dupk, true)
    }
    assert_equal "Element relation/ has duplicate tags with key dup", message_create.message
    message_update = assert_raise(OSM::APIDuplicateTagsError) {
      Relation.from_xml(dupk, false)
    }
    assert_equal "Element relation/23 has duplicate tags with key dup", message_update.message
  end

  def test_relation_members
    relation = current_relations(:relation_with_versions)
    members = Relation.find(relation.id).relation_members
    assert_equal 3, members.count
    assert_equal "some node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal 15, members[0].member_id
    assert_equal "some way", members[1].member_role
    assert_equal "Way", members[1].member_type
    assert_equal 4, members[1].member_id
    assert_equal "some relation", members[2].member_role
    assert_equal "Relation", members[2].member_type
    assert_equal 7, members[2].member_id
  end

  def test_relations
    relation = current_relations(:relation_with_versions)
    members = Relation.find(relation.id).members
    assert_equal 3, members.count
    assert_equal ["Node", 15, "some node"], members[0]
    assert_equal ["Way", 4, "some way"], members[1]
    assert_equal ["Relation", 7, "some relation"], members[2]
  end

  def test_relation_tags
    relation = current_relations(:relation_with_versions)
    tags = Relation.find(relation.id).relation_tags.order(:k)
    assert_equal 2, tags.count
    assert_equal "testing", tags[0].k 
    assert_equal "added in relation version 3", tags[0].v
    assert_equal "testing two", tags[1].k
    assert_equal "modified in relation version 4", tags[1].v
  end

  def test_tags
    relation = current_relations(:relation_with_versions)
    tags = Relation.find(relation.id).tags
    assert_equal 2, tags.size
    assert_equal "added in relation version 3", tags["testing"]
    assert_equal "modified in relation version 4", tags["testing two"]
  end
end
