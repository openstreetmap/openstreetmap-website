require File.dirname(__FILE__) + '/../test_helper'

class RelationTest < ActiveSupport::TestCase
  api_fixtures
  
  def test_relation_count
    assert_equal 6, Relation.count
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
end
