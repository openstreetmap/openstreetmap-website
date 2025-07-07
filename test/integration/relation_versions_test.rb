require "test_helper"

class RelationVersionsTest < ActionDispatch::IntegrationTest
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
end
