# frozen_string_literal: true

require "test_helper"

class RelationVersionsTest < ActionDispatch::IntegrationTest
  ##
  # test that, when tags are updated on a relation, the correct things
  # happen to the correct tables and the API gives sensible results.
  # this is to test a case that gregory marler noticed and posted to
  # josm-dev.
  def test_update_relation_tags
    user = create(:user)
    changeset = create(:changeset, :user => user)
    relation = create(:relation)
    create_list(:relation_tag, 4, :relation => relation)

    auth_header = bearer_authorization_header user

    get api_relation_path(relation)
    assert_response :success
    rel = xml_parse(@response.body)
    rel_id = rel.find("//osm/relation").first["id"].to_i

    # alter one of the tags
    tag = rel.find("//osm/relation/tag").first
    tag["v"] = "some changed value"
    update_changeset(rel, changeset.id)
    put api_relation_path(rel_id), :params => rel.to_s, :headers => auth_header
    assert_response :success, "can't update relation: #{@response.body}"
    new_version = @response.body.to_i

    # check that the downloaded tags are the same as the uploaded tags...
    get api_relation_path(rel_id)
    assert_tags_equal_response rel

    # check the original one in the current_* table again
    get api_relation_path(relation)
    assert_tags_equal_response rel

    # now check the version in the history
    get api_relation_version_path(relation, new_version)
    assert_tags_equal_response rel
  end

  ##
  # test that, when tags are updated on a relation when using the diff
  # upload function, the correct things happen to the correct tables
  # and the API gives sensible results. this is to test a case that
  # gregory marler noticed and posted to josm-dev.
  def test_update_relation_tags_via_upload
    user = create(:user)
    changeset = create(:changeset, :user => user)
    relation = create(:relation)
    create_list(:relation_tag, 4, :relation => relation)

    auth_header = bearer_authorization_header user

    get api_relation_path(relation)
    assert_response :success
    rel = xml_parse(@response.body)
    rel_id = rel.find("//osm/relation").first["id"].to_i

    # alter one of the tags
    tag = rel.find("//osm/relation/tag").first
    tag["v"] = "some changed value"
    update_changeset(rel, changeset.id)
    new_version = nil
    with_controller(Api::ChangesetsController.new) do
      doc = OSM::API.new.xml_doc
      change = XML::Node.new "osmChange"
      doc.root = change
      modify = XML::Node.new "modify"
      change << modify
      modify << doc.import(rel.find("//osm/relation").first)

      post api_changeset_upload_path(changeset), :params => doc.to_s, :headers => auth_header
      assert_response :success, "can't upload diff relation: #{@response.body}"
      new_version = xml_parse(@response.body).find("//diffResult/relation").first["new_version"].to_i
    end

    # check that the downloaded tags are the same as the uploaded tags...
    get api_relation_path(rel_id)
    assert_tags_equal_response rel

    # check the original one in the current_* table again
    get api_relation_path(relation)
    assert_tags_equal_response rel

    # now check the version in the history
    get api_relation_version_path(relation, new_version)
    assert_tags_equal_response rel
  end

  ##
  # check that relations are ordered
  def test_relation_member_ordering
    user = create(:user)
    changeset = create(:changeset, :user => user)
    node1 = create(:node)
    node2 = create(:node)
    node3 = create(:node)
    way1 = create(:way_with_nodes, :nodes_count => 2)
    way2 = create(:way_with_nodes, :nodes_count => 2)

    auth_header = bearer_authorization_header user

    doc_str = <<~OSM
      <osm>
        <relation changeset='#{changeset.id}'>
        <member ref='#{node1.id}' type='node' role='first'/>
        <member ref='#{node2.id}' type='node' role='second'/>
        <member ref='#{way1.id}' type='way' role='third'/>
        <member ref='#{way2.id}' type='way' role='fourth'/>
        </relation>
      </osm>
    OSM
    doc = XML::Parser.string(doc_str).parse

    post api_relations_path, :params => doc.to_s, :headers => auth_header
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # get it back and check the ordering
    get api_relation_path(relation_id)
    assert_members_equal_response doc

    # check the ordering in the history tables:
    get api_relation_version_path(relation_id, 1)
    assert_members_equal_response doc, "can't read back version 2 of the relation"

    # insert a member at the front
    new_member = XML::Node.new "member"
    new_member["ref"] = node3.id.to_s
    new_member["type"] = "node"
    new_member["role"] = "new first"
    doc.find("//osm/relation").first.child.prev = new_member
    # update the version, should be 1?
    doc.find("//osm/relation").first["id"] = relation_id.to_s
    doc.find("//osm/relation").first["version"] = 1.to_s

    # upload the next version of the relation
    put api_relation_path(relation_id), :params => doc.to_s, :headers => auth_header
    assert_response :success, "can't update relation: #{@response.body}"
    assert_equal 2, @response.body.to_i

    # get it back again and check the ordering again
    get api_relation_path(relation_id)
    assert_members_equal_response doc

    # check the ordering in the history tables:
    get api_relation_version_path(relation_id, 2)
    assert_members_equal_response doc, "can't read back version 2 of the relation"
  end

  ##
  # check that relations can contain duplicate members
  def test_relation_member_duplicates
    private_user = create(:user, :data_public => false)
    user = create(:user)
    changeset = create(:changeset, :user => user)
    node1 = create(:node)
    node2 = create(:node)

    doc_str = <<~OSM
      <osm>
        <relation changeset='#{changeset.id}'>
        <member ref='#{node1.id}' type='node' role='forward'/>
        <member ref='#{node2.id}' type='node' role='forward'/>
        <member ref='#{node1.id}' type='node' role='forward'/>
        <member ref='#{node2.id}' type='node' role='forward'/>
        </relation>
      </osm>
    OSM
    doc = XML::Parser.string(doc_str).parse

    ## First try with the private user
    auth_header = bearer_authorization_header private_user

    post api_relations_path, :params => doc.to_s, :headers => auth_header
    assert_response :forbidden

    ## Now try with the public user
    auth_header = bearer_authorization_header user

    post api_relations_path, :params => doc.to_s, :headers => auth_header
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # get it back and check the ordering
    get api_relation_path(relation_id)
    assert_members_equal_response doc

    # check the ordering in the history tables:
    get api_relation_version_path(relation_id, 1)
    assert_members_equal_response doc, "can't read back version 1 of the relation"
  end

  ##
  # test that the ordering of elements in the history is the same as in current.
  def test_history_ordering
    user = create(:user)
    changeset = create(:changeset, :user => user)
    node1 = create(:node)
    node2 = create(:node)
    node3 = create(:node)
    node4 = create(:node)

    doc_str = <<~OSM
      <osm>
        <relation changeset='#{changeset.id}'>
        <member ref='#{node1.id}' type='node' role='forward'/>
        <member ref='#{node4.id}' type='node' role='forward'/>
        <member ref='#{node3.id}' type='node' role='forward'/>
        <member ref='#{node2.id}' type='node' role='forward'/>
        </relation>
      </osm>
    OSM
    doc = XML::Parser.string(doc_str).parse
    auth_header = bearer_authorization_header user

    post api_relations_path, :params => doc.to_s, :headers => auth_header
    assert_response :success, "can't create a relation: #{@response.body}"
    relation_id = @response.body.to_i

    # check the ordering in the current tables:
    get api_relation_path(relation_id)
    assert_members_equal_response doc

    # check the ordering in the history tables:
    get api_relation_version_path(relation_id, 1)
    assert_members_equal_response doc, "can't read back version 1 of the relation"
  end

  private

  ##
  # assert that tags on relation document +rel+
  # are equal to tags in response
  def assert_tags_equal_response(rel)
    assert_response :success
    response_xml = xml_parse(@response.body)

    # turn the XML doc into tags hashes
    rel_tags = get_tags_as_hash(rel)
    response_tags = get_tags_as_hash(response_xml)

    assert_equal rel_tags, response_tags, "Tags should be identical."
  end

  ##
  # checks that the XML document and the response have
  # members in the same order.
  def assert_members_equal_response(doc, response_message = "can't read back the relation")
    assert_response :success, "#{response_message}: #{@response.body}"
    new_doc = XML::Parser.string(@response.body).parse

    doc_members = doc.find("//osm/relation/member").collect do |m|
      [m["ref"].to_i, m["type"].to_sym, m["role"]]
    end

    new_members = new_doc.find("//osm/relation/member").collect do |m|
      [m["ref"].to_i, m["type"].to_sym, m["role"]]
    end

    assert_equal doc_members, new_members, "members are not equal - ordering is wrong? (#{doc}, #{@response.body})"
  end

  ##
  # returns a k->v hash of tags from an xml doc
  def get_tags_as_hash(a)
    a.find("//osm/relation/tag").to_h do |tag|
      [tag["k"], tag["v"]]
    end
  end

  ##
  # update the changeset_id of a node element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, "changeset", changeset_id)
  end

  ##
  # update an attribute in the node element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/relation").first[name] = value.to_s
    xml
  end

  ##
  # parse some xml
  def xml_parse(xml)
    parser = XML::Parser.string(xml)
    parser.parse
  end
end
