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

  private

  ##
  # update the changeset_id of a way element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, "changeset", changeset_id)
  end

  ##
  # update an attribute in a way element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/way").first[name] = value.to_s
    xml
  end
end
