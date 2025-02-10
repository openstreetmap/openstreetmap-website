require "test_helper"

class NodeVersionsTest < ActionDispatch::IntegrationTest
  ##
  # test the version call by submitting several revisions of a new node
  # to the API and ensuring that later calls to version return the
  # matching versions of the object.
  def test_version
    private_user = create(:user, :data_public => false)
    private_node = create(:node, :with_history, :version => 4, :lat => 0, :lon => 0, :changeset => create(:changeset, :user => private_user))
    user = create(:user)
    node = create(:node, :with_history, :version => 4, :lat => 0, :lon => 0, :changeset => create(:changeset, :user => user))
    create_list(:node_tag, 2, :node => node)
    # Ensure that the current tags are propagated to the history too
    propagate_tags(node, node.old_nodes.last)

    ## First try this with a non-public user
    auth_header = bearer_authorization_header private_user

    # setup a simple XML node
    xml_doc = xml_for_node(private_node)
    xml_node = xml_doc.find("//osm/node").first
    node_id = private_node.id

    # keep a hash of the versions => string, as we'll need something
    # to test against later
    versions = {}

    # save a version for later checking
    versions[xml_node["version"]] = xml_doc.to_s

    # randomly move the node about
    3.times do
      # move the node somewhere else
      xml_node["lat"] = precision(rand - 0.5).to_s
      xml_node["lon"] = precision(rand - 0.5).to_s
      with_controller(NodesController.new) do
        put api_node_path(node_id), :params => xml_doc.to_s, :headers => auth_header
        assert_response :forbidden, "Should have rejected node update"
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # add a bunch of random tags
    3.times do
      xml_tag = XML::Node.new("tag")
      xml_tag["k"] = random_string
      xml_tag["v"] = random_string
      xml_node << xml_tag
      with_controller(NodesController.new) do
        put api_node_path(node_id), :params => xml_doc.to_s, :headers => auth_header
        assert_response :forbidden,
                        "should have rejected node #{node_id} (#{@response.body}) with forbidden"
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # probably should check that they didn't get written to the database

    ## Now do it with the public user
    auth_header = bearer_authorization_header user

    # setup a simple XML node

    xml_doc = xml_for_node(node)
    xml_node = xml_doc.find("//osm/node").first
    node_id = node.id

    # keep a hash of the versions => string, as we'll need something
    # to test against later
    versions = {}

    # save a version for later checking
    versions[xml_node["version"]] = xml_doc.to_s

    # randomly move the node about
    3.times do
      # move the node somewhere else
      xml_node["lat"] = precision(rand - 0.5).to_s
      xml_node["lon"] = precision(rand - 0.5).to_s
      with_controller(NodesController.new) do
        put api_node_path(node_id), :params => xml_doc.to_s, :headers => auth_header
        assert_response :success
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # add a bunch of random tags
    3.times do
      xml_tag = XML::Node.new("tag")
      xml_tag["k"] = random_string
      xml_tag["v"] = random_string
      xml_node << xml_tag
      with_controller(NodesController.new) do
        put api_node_path(node_id), :params => xml_doc.to_s, :headers => auth_header
        assert_response :success,
                        "couldn't update node #{node_id} (#{@response.body})"
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # check all the versions
    versions.each_key do |key|
      get api_node_version_path(node_id, key.to_i)

      assert_response :success,
                      "couldn't get version #{key.to_i} of node #{node_id}"

      check_node = Node.from_xml(versions[key])
      api_node = Node.from_xml(@response.body.to_s)

      assert_nodes_are_equal check_node, api_node
    end
  end

  ##
  # Test that getting the current version is identical to picking
  # that version with the version URI call.
  def test_current_version
    node = create(:node, :with_history)
    used_node = create(:node, :with_history)
    create(:way_node, :node => used_node)
    node_used_by_relationship = create(:node, :with_history)
    create(:relation_member, :member => node_used_by_relationship)
    node_with_versions = create(:node, :with_history, :version => 4)

    create(:node_tag, :node => node)
    create(:node_tag, :node => used_node)
    create(:node_tag, :node => node_used_by_relationship)
    create(:node_tag, :node => node_with_versions)
    propagate_tags(node, node.old_nodes.last)
    propagate_tags(used_node, used_node.old_nodes.last)
    propagate_tags(node_used_by_relationship, node_used_by_relationship.old_nodes.last)
    propagate_tags(node_with_versions, node_with_versions.old_nodes.last)

    check_current_version(node)
    check_current_version(used_node)
    check_current_version(node_used_by_relationship)
    check_current_version(node_with_versions)
  end

  private

  def check_current_version(node_id)
    # get the current version of the node
    current_node = with_controller(NodesController.new) do
      get api_node_path(node_id)
      assert_response :success, "cant get current node #{node_id}"
      Node.from_xml(@response.body)
    end
    assert_not_nil current_node, "getting node #{node_id} returned nil"

    # get the "old" version of the node from the old_node interface
    get api_node_version_path(node_id, current_node.version)
    assert_response :success, "cant get old node #{node_id}, v#{current_node.version}"
    old_node = Node.from_xml(@response.body)

    # check the nodes are the same
    assert_nodes_are_equal current_node, old_node
  end

  ##
  # returns a 16 character long string with some nasty characters in it.
  # this ought to stress-test the tag handling as well as the versioning.
  def random_string
    letters = [["!", '"', "$", "&", ";", "@"],
               ("a".."z").to_a,
               ("A".."Z").to_a,
               ("0".."9").to_a].flatten
    (1..16).map { letters[rand(letters.length)] }.join
  end

  ##
  # truncate a floating point number to the scale that it is stored in
  # the database. otherwise rounding errors can produce failing unit
  # tests when they shouldn't.
  def precision(f)
    (f * GeoRecord::SCALE).round.to_f / GeoRecord::SCALE
  end

  def propagate_tags(node, old_node)
    node.tags.each do |k, v|
      create(:old_node_tag, :old_node => old_node, :k => k, :v => v)
    end
  end
end
