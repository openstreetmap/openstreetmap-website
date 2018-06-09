require "test_helper"

class RelationTest < ActiveSupport::TestCase
  def test_from_xml_no_id
    noid = "<osm><relation version='12' changeset='23' /></osm>"
    assert_nothing_raised do
      Relation.from_xml(noid, true)
    end
    message = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(noid, false)
    end
    assert_match(/ID is required when updating/, message.message)
  end

  def test_from_xml_no_changeset_id
    nocs = "<osm><relation id='123' version='12' /></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(nocs, true)
    end
    assert_match(/Changeset id is missing/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(nocs, false)
    end
    assert_match(/Changeset id is missing/, message_update.message)
  end

  def test_from_xml_no_version
    no_version = "<osm><relation id='123' changeset='23' /></osm>"
    assert_nothing_raised do
      Relation.from_xml(no_version, true)
    end
    message_update = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(no_version, false)
    end
    assert_match(/Version is required when updating/, message_update.message)
  end

  def test_from_xml_id_zero
    id_list = ["", "0", "00", "0.0", "a"]
    id_list.each do |id|
      zero_id = "<osm><relation id='#{id}' changeset='332' version='23' /></osm>"
      assert_nothing_raised do
        Relation.from_xml(zero_id, true)
      end
      message_update = assert_raise(OSM::APIBadUserInput) do
        Relation.from_xml(zero_id, false)
      end
      assert_match(/ID of relation cannot be zero when updating/, message_update.message)
    end
  end

  def test_from_xml_no_text
    no_text = ""
    message_create = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(no_text, true)
    end
    assert_match(/Must specify a string with one or more characters/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(no_text, false)
    end
    assert_match(/Must specify a string with one or more characters/, message_update.message)
  end

  def test_from_xml_no_k_v
    nokv = "<osm><relation id='23' changeset='23' version='23'><tag /></relation></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(nokv, true)
    end
    assert_match(/tag is missing key/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(nokv, false)
    end
    assert_match(/tag is missing key/, message_update.message)
  end

  def test_from_xml_no_v
    no_v = "<osm><relation id='23' changeset='23' version='23'><tag k='key' /></relation></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(no_v, true)
    end
    assert_match(/tag is missing value/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Relation.from_xml(no_v, false)
    end
    assert_match(/tag is missing value/, message_update.message)
  end

  def test_from_xml_duplicate_k
    dupk = "<osm><relation id='23' changeset='23' version='23'><tag k='dup' v='test'/><tag k='dup' v='tester'/></relation></osm>"
    message_create = assert_raise(OSM::APIDuplicateTagsError) do
      Relation.from_xml(dupk, true)
    end
    assert_equal "Element relation/ has duplicate tags with key dup", message_create.message
    message_update = assert_raise(OSM::APIDuplicateTagsError) do
      Relation.from_xml(dupk, false)
    end
    assert_equal "Element relation/23 has duplicate tags with key dup", message_update.message
  end

  def test_relation_members
    relation = create(:relation)
    node = create(:node)
    way = create(:way)
    other_relation = create(:relation)
    create(:relation_member, :relation => relation, :member => node, :member_role => "some node")
    create(:relation_member, :relation => relation, :member => way, :member_role => "some way")
    create(:relation_member, :relation => relation, :member => other_relation, :member_role => "some relation")

    members = Relation.find(relation.id).relation_members
    assert_equal 3, members.count
    assert_equal "some node", members[0].member_role
    assert_equal "Node", members[0].member_type
    assert_equal node.id, members[0].member_id
    assert_equal "some way", members[1].member_role
    assert_equal "Way", members[1].member_type
    assert_equal way.id, members[1].member_id
    assert_equal "some relation", members[2].member_role
    assert_equal "Relation", members[2].member_type
    assert_equal other_relation.id, members[2].member_id
  end

  def test_relations
    relation = create(:relation)
    node = create(:node)
    way = create(:way)
    other_relation = create(:relation)
    create(:relation_member, :relation => relation, :member => node, :member_role => "some node")
    create(:relation_member, :relation => relation, :member => way, :member_role => "some way")
    create(:relation_member, :relation => relation, :member => other_relation, :member_role => "some relation")

    members = Relation.find(relation.id).members
    assert_equal 3, members.count
    assert_equal ["Node", node.id, "some node"], members[0]
    assert_equal ["Way", way.id, "some way"], members[1]
    assert_equal ["Relation", other_relation.id, "some relation"], members[2]
  end

  def test_relation_tags
    relation = create(:relation)
    taglist = create_list(:relation_tag, 2, :relation => relation)

    tags = Relation.find(relation.id).relation_tags.order(:k)
    assert_equal taglist.count, tags.count
    taglist.sort_by!(&:k).each_index do |i|
      assert_equal taglist[i].k, tags[i].k
      assert_equal taglist[i].v, tags[i].v
    end
  end

  def test_tags
    relation = create(:relation)
    taglist = create_list(:relation_tag, 2, :relation => relation)

    tags = Relation.find(relation.id).tags
    assert_equal taglist.count, tags.count
    taglist.each do |tag|
      assert_equal tag.v, tags[tag.k]
    end
  end

  def test_containing_relation_members
    relation = create(:relation)
    super_relation = create(:relation)
    create(:relation_member, :relation => super_relation, :member => relation)

    crm = Relation.find(relation.id).containing_relation_members.order(:relation_id)
    #    assert_equal 1, crm.size
    assert_equal super_relation.id, crm.first.relation_id
    assert_equal "Relation", crm.first.member_type
    assert_equal relation.id, crm.first.member_id
    assert_equal super_relation.id, crm.first.relation.id
  end

  def test_containing_relations
    relation = create(:relation)
    super_relation = create(:relation)
    create(:relation_member, :relation => super_relation, :member => relation)

    cr = Relation.find(relation.id).containing_relations.order(:id)
    assert_equal 1, cr.size
    assert_equal super_relation.id, cr.first.id
  end
end
