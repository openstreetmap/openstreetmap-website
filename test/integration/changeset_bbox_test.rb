# frozen_string_literal: true

require "test_helper"

class ChangesetBboxTest < ActionDispatch::IntegrationTest
  ##
  # check that the bounding box of a changeset gets updated correctly
  def test_changeset_bbox
    way = create(:way)
    create(:way_node, :way => way, :node => create(:node, :lat => 0.3, :lon => 0.3))

    auth_header = bearer_authorization_header

    # create a new changeset
    xml = "<osm><changeset/></osm>"
    post api_changesets_path, :params => xml, :headers => auth_header
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    # add a single node to it
    with_controller(NodesController.new) do
      xml = "<osm><node lon='0.1' lat='0.2' changeset='#{changeset_id}'/></osm>"
      post api_nodes_path, :params => xml, :headers => auth_header
      assert_response :success, "Couldn't create node."
    end

    # get the bounding box back from the changeset
    get api_changeset_path(changeset_id)
    assert_response :success, "Couldn't read back changeset."
    assert_dom "osm>changeset[min_lon='0.1000000']", 1
    assert_dom "osm>changeset[max_lon='0.1000000']", 1
    assert_dom "osm>changeset[min_lat='0.2000000']", 1
    assert_dom "osm>changeset[max_lat='0.2000000']", 1

    # add another node to it
    with_controller(NodesController.new) do
      xml = "<osm><node lon='0.2' lat='0.1' changeset='#{changeset_id}'/></osm>"
      post api_nodes_path, :params => xml, :headers => auth_header
      assert_response :success, "Couldn't create second node."
    end

    # get the bounding box back from the changeset
    get api_changeset_path(changeset_id)
    assert_response :success, "Couldn't read back changeset for the second time."
    assert_dom "osm>changeset[min_lon='0.1000000']", 1
    assert_dom "osm>changeset[max_lon='0.2000000']", 1
    assert_dom "osm>changeset[min_lat='0.1000000']", 1
    assert_dom "osm>changeset[max_lat='0.2000000']", 1

    # add (delete) a way to it, which contains a point at (3,3)
    with_controller(WaysController.new) do
      xml = update_changeset(xml_for_way(way), changeset_id)
      delete api_way_path(way), :params => xml.to_s, :headers => auth_header
      assert_response :success, "Couldn't delete a way."
    end

    # get the bounding box back from the changeset
    get api_changeset_path(changeset_id)
    assert_response :success, "Couldn't read back changeset for the third time."
    assert_dom "osm>changeset[min_lon='0.1000000']", 1
    assert_dom "osm>changeset[max_lon='0.3000000']", 1
    assert_dom "osm>changeset[min_lat='0.1000000']", 1
    assert_dom "osm>changeset[max_lat='0.3000000']", 1
  end

  ##
  # when a relation's tag is modified then it should put the bounding
  # box of all its members into the changeset.
  def test_relation_tag_modify_bounding_box
    relation = create(:relation)
    node1 = create(:node, :lat => 0.3, :lon => 0.3)
    node2 = create(:node, :lat => 0.5, :lon => 0.5)
    way = create(:way)
    create(:way_node, :way => way, :node => node1)
    create(:relation_member, :relation => relation, :member => way)
    create(:relation_member, :relation => relation, :member => node2)
    # the relation contains nodes1 and node2 (node1
    # indirectly via the way), so the bbox should be [0.3,0.3,0.5,0.5].
    check_changeset_modify(BoundingBox.new(0.3, 0.3, 0.5, 0.5)) do |changeset_id, auth_header|
      # add a tag to an existing relation
      relation_xml = xml_for_relation(relation)
      relation_element = relation_xml.find("//osm/relation").first
      new_tag = XML::Node.new("tag")
      new_tag["k"] = "some_new_tag"
      new_tag["v"] = "some_new_value"
      relation_element << new_tag

      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)

      # upload the change
      put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
      assert_response :success, "can't update relation for tag/bbox test"
    end
  end

  ##
  # add a member to a relation and check the bounding box is only that
  # element.
  def test_relation_add_member_bounding_box
    relation = create(:relation)
    node1 = create(:node, :lat => 4, :lon => 4)
    node2 = create(:node, :lat => 7, :lon => 7)
    way1 = create(:way)
    create(:way_node, :way => way1, :node => create(:node, :lat => 8, :lon => 8))
    way2 = create(:way)
    create(:way_node, :way => way2, :node => create(:node, :lat => 9, :lon => 9), :sequence_id => 1)
    create(:way_node, :way => way2, :node => create(:node, :lat => 10, :lon => 10), :sequence_id => 2)

    [node1, node2, way1, way2].each do |element|
      bbox = element.bbox.to_unscaled
      check_changeset_modify(bbox) do |changeset_id, auth_header|
        relation_xml = xml_for_relation(Relation.find(relation.id))
        relation_element = relation_xml.find("//osm/relation").first
        new_member = XML::Node.new("member")
        new_member["ref"] = element.id.to_s
        new_member["type"] = element.class.to_s.downcase
        new_member["role"] = "some_role"
        relation_element << new_member

        # update changeset ID to point to new changeset
        update_changeset(relation_xml, changeset_id)

        # upload the change
        put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
        assert_response :success, "can't update relation for add #{element.class}/bbox test: #{@response.body}"

        # get it back and check the ordering
        get api_relation_path(relation)
        assert_members_equal_response relation_xml
      end
    end
  end

  ##
  # remove a member from a relation and check the bounding box is
  # only that element.
  def test_relation_remove_member_bounding_box
    relation = create(:relation)
    node1 = create(:node, :lat => 3, :lon => 3)
    node2 = create(:node, :lat => 5, :lon => 5)
    create(:relation_member, :relation => relation, :member => node1)
    create(:relation_member, :relation => relation, :member => node2)

    check_changeset_modify(BoundingBox.new(5, 5, 5, 5)) do |changeset_id, auth_header|
      # remove node 5 (5,5) from an existing relation
      relation_xml = xml_for_relation(relation)
      relation_xml
        .find("//osm/relation/member[@type='node'][@ref='#{node2.id}']")
        .first.remove!

      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)

      # upload the change
      put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
      assert_response :success, "can't update relation for remove node/bbox test"
    end
  end

  ##
  # remove all the members from a relation. the result is pretty useless, but
  # still technically valid.
  def test_relation_remove_all_members
    relation = create(:relation)
    node1 = create(:node, :lat => 0.3, :lon => 0.3)
    node2 = create(:node, :lat => 0.5, :lon => 0.5)
    way = create(:way)
    create(:way_node, :way => way, :node => node1)
    create(:relation_member, :relation => relation, :member => way)
    create(:relation_member, :relation => relation, :member => node2)

    check_changeset_modify(BoundingBox.new(0.3, 0.3, 0.5, 0.5)) do |changeset_id, auth_header|
      relation_xml = xml_for_relation(relation)
      relation_xml
        .find("//osm/relation/member")
        .each(&:remove!)

      # update changeset ID to point to new changeset
      update_changeset(relation_xml, changeset_id)

      # upload the change
      put api_relation_path(relation), :params => relation_xml.to_s, :headers => auth_header
      assert_response :success, "can't update relation for remove all members test"
      checkrelation = Relation.find(relation.id)
      assert_not_nil(checkrelation,
                     "uploaded relation not found in database after upload")
      assert_equal(0, checkrelation.members.length,
                   "relation contains members but they should have all been deleted")
    end
  end

  private

  ##
  # create a changeset and yield to the caller to set it up, then assert
  # that the changeset bounding box is +bbox+.
  def check_changeset_modify(bbox)
    ## First test with the private user to check that you get a forbidden
    auth_header = bearer_authorization_header create(:user, :data_public => false)

    # create a new changeset for this operation, so we are assured
    # that the bounding box will be newly-generated.
    with_controller(Api::ChangesetsController.new) do
      xml = "<osm><changeset/></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :forbidden, "shouldn't be able to create changeset for modify test, as should get forbidden"
    end

    ## Now do the whole thing with the public user
    auth_header = bearer_authorization_header

    # create a new changeset for this operation, so we are assured
    # that the bounding box will be newly-generated.
    changeset_id = with_controller(Api::ChangesetsController.new) do
      xml = "<osm><changeset/></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success, "couldn't create changeset for modify test"
      @response.body.to_i
    end

    # go back to the block to do the actual modifies
    yield changeset_id, auth_header

    # now download the changeset to check its bounding box
    with_controller(Api::ChangesetsController.new) do
      get api_changeset_path(changeset_id)
      assert_response :success, "can't re-read changeset for modify test"
      assert_select "osm>changeset", 1, "Changeset element doesn't exist in #{@response.body}"
      assert_select "osm>changeset[id='#{changeset_id}']", 1, "Changeset id=#{changeset_id} doesn't exist in #{@response.body}"
      assert_select "osm>changeset[min_lon='#{format('%<lon>.7f', :lon => bbox.min_lon)}']", 1, "Changeset min_lon wrong in #{@response.body}"
      assert_select "osm>changeset[min_lat='#{format('%<lat>.7f', :lat => bbox.min_lat)}']", 1, "Changeset min_lat wrong in #{@response.body}"
      assert_select "osm>changeset[max_lon='#{format('%<lon>.7f', :lon => bbox.max_lon)}']", 1, "Changeset max_lon wrong in #{@response.body}"
      assert_select "osm>changeset[max_lat='#{format('%<lat>.7f', :lat => bbox.max_lat)}']", 1, "Changeset max_lat wrong in #{@response.body}"
    end
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
  # update the changeset_id of an element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, "changeset", changeset_id)
  end

  ##
  # update an attribute in an element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/*[self::node or self::way or self::relation]").first[name] = value.to_s
    xml
  end
end
