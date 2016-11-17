require "test_helper"
require "old_node_controller"

class OldNodeControllerTest < ActionController::TestCase
  api_fixtures

  #
  # TODO: test history
  #

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/node/1/history", :method => :get },
      { :controller => "old_node", :action => "history", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/node/1/2", :method => :get },
      { :controller => "old_node", :action => "version", :id => "1", :version => "2" }
    )
    assert_routing(
      { :path => "/api/0.6/node/1/2/redact", :method => :post },
      { :controller => "old_node", :action => "redact", :id => "1", :version => "2" }
    )
  end

  ##
  # test the version call by submitting several revisions of a new node
  # to the API and ensuring that later calls to version return the
  # matching versions of the object.
  #
  ##
  # FIXME: Move this test to being an integration test since it spans multiple controllers
  def test_version
    ## First try this with a non-public user
    basic_authorization(users(:normal_user).email, "test")

    # setup a simple XML node
    xml_doc = current_nodes(:visible_node).to_xml
    xml_node = xml_doc.find("//osm/node").first
    nodeid = current_nodes(:visible_node).id

    # keep a hash of the versions => string, as we'll need something
    # to test against later
    versions = {}

    # save a version for later checking
    versions[xml_node["version"]] = xml_doc.to_s

    # randomly move the node about
    20.times do
      # move the node somewhere else
      xml_node["lat"] = precision(rand * 180 - 90).to_s
      xml_node["lon"] = precision(rand * 360 - 180).to_s
      with_controller(NodeController.new) do
        content xml_doc
        put :update, :id => nodeid
        assert_response :forbidden, "Should have rejected node update"
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # add a bunch of random tags
    30.times do
      xml_tag = XML::Node.new("tag")
      xml_tag["k"] = random_string
      xml_tag["v"] = random_string
      xml_node << xml_tag
      with_controller(NodeController.new) do
        content xml_doc
        put :update, :id => nodeid
        assert_response :forbidden,
                        "should have rejected node #{nodeid} (#{@response.body}) with forbidden"
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # probably should check that they didn't get written to the database

    ## Now do it with the public user
    basic_authorization(users(:public_user).email, "test")

    # setup a simple XML node
    create_list(:node_tag, 2, :node => current_nodes(:node_with_versions))
    xml_doc = current_nodes(:node_with_versions).to_xml
    xml_node = xml_doc.find("//osm/node").first
    nodeid = current_nodes(:node_with_versions).id

    # Ensure that the current tags are propagated to the history too
    propagate_tags(current_nodes(:node_with_versions), nodes(:node_with_versions_v4))

    # keep a hash of the versions => string, as we'll need something
    # to test against later
    versions = {}

    # save a version for later checking
    versions[xml_node["version"]] = xml_doc.to_s

    # randomly move the node about
    20.times do
      # move the node somewhere else
      xml_node["lat"] = precision(rand * 180 - 90).to_s
      xml_node["lon"] = precision(rand * 360 - 180).to_s
      with_controller(NodeController.new) do
        content xml_doc
        put :update, :id => nodeid
        assert_response :success
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # add a bunch of random tags
    30.times do
      xml_tag = XML::Node.new("tag")
      xml_tag["k"] = random_string
      xml_tag["v"] = random_string
      xml_node << xml_tag
      with_controller(NodeController.new) do
        content xml_doc
        put :update, :id => nodeid
        assert_response :success,
                        "couldn't update node #{nodeid} (#{@response.body})"
        xml_node["version"] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node["version"]] = xml_doc.to_s
    end

    # check all the versions
    versions.keys.each do |key|
      get :version, :id => nodeid, :version => key.to_i

      assert_response :success,
                      "couldn't get version #{key.to_i} of node #{nodeid}"

      check_node = Node.from_xml(versions[key])
      api_node = Node.from_xml(@response.body.to_s)

      assert_nodes_are_equal check_node, api_node
    end
  end

  def test_not_found_version
    check_not_found_id_version(70000, 312344)
    check_not_found_id_version(-1, -13)
    check_not_found_id_version(nodes(:visible_node).id, 24354)
    check_not_found_id_version(24356, nodes(:visible_node).version)
  end

  def check_not_found_id_version(id, version)
    get :version, :id => id, :version => version
    assert_response :not_found
  rescue ActionController::UrlGenerationError => ex
    assert_match /No route matches/, ex.to_s
  end

  ##
  # Test that getting the current version is identical to picking
  # that version with the version URI call.
  def test_current_version
    create(:node_tag, :node => current_nodes(:visible_node))
    create(:node_tag, :node => current_nodes(:used_node_1))
    create(:node_tag, :node => current_nodes(:used_node_2))
    create(:node_tag, :node => current_nodes(:node_used_by_relationship))
    create(:node_tag, :node => current_nodes(:node_with_versions))
    propagate_tags(current_nodes(:visible_node), nodes(:visible_node))
    propagate_tags(current_nodes(:used_node_1), nodes(:used_node_1))
    propagate_tags(current_nodes(:used_node_2), nodes(:used_node_2))
    propagate_tags(current_nodes(:node_used_by_relationship), nodes(:node_used_by_relationship))
    propagate_tags(current_nodes(:node_with_versions), nodes(:node_with_versions_v4))

    check_current_version(current_nodes(:visible_node))
    check_current_version(current_nodes(:used_node_1))
    check_current_version(current_nodes(:used_node_2))
    check_current_version(current_nodes(:node_used_by_relationship))
    check_current_version(current_nodes(:node_with_versions))
  end

  ##
  # test the redaction of an old version of a node, while not being
  # authorised.
  def test_redact_node_unauthorised
    do_redact_node(nodes(:node_with_versions_v3),
                   redactions(:example))
    assert_response :unauthorized, "should need to be authenticated to redact."
  end

  ##
  # test the redaction of an old version of a node, while being
  # authorised as a normal user.
  def test_redact_node_normal_user
    basic_authorization(users(:public_user).email, "test")

    do_redact_node(nodes(:node_with_versions_v3),
                   redactions(:example))
    assert_response :forbidden, "should need to be moderator to redact."
  end

  ##
  # test that, even as moderator, the current version of a node
  # can't be redacted.
  def test_redact_node_current_version
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_node(nodes(:node_with_versions_v4),
                   redactions(:example))
    assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
  end

  ##
  # test that redacted nodes aren't visible, regardless of
  # authorisation except as moderator...
  def test_version_redacted
    node = nodes(:redacted_node_redacted_version)

    get :version, :id => node.node_id, :version => node.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API."

    # not even to a logged-in user
    basic_authorization(users(:public_user).email, "test")
    get :version, :id => node.node_id, :version => node.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API, even when logged in."
  end

  ##
  # test that redacted nodes aren't visible in the history
  def test_history_redacted
    node = nodes(:redacted_node_redacted_version)

    get :history, :id => node.node_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 0, "redacted node #{node.node_id} version #{node.version} shouldn't be present in the history."

    # not even to a logged-in user
    basic_authorization(users(:public_user).email, "test")
    get :history, :id => node.node_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 0, "redacted node #{node.node_id} version #{node.version} shouldn't be present in the history, even when logged in."
  end

  ##
  # test the redaction of an old version of a node, while being
  # authorised as a moderator.
  def test_redact_node_moderator
    node = nodes(:node_with_versions_v3)
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_node(node, redactions(:example))
    assert_response :success, "should be OK to redact old version as moderator."

    # check moderator can still see the redacted data, when passing
    # the appropriate flag
    get :version, :id => node.node_id, :version => node.version
    assert_response :forbidden, "After redaction, node should be gone for moderator, when flag not passed."
    get :version, :id => node.node_id, :version => node.version, :show_redactions => "true"
    assert_response :success, "After redaction, node should not be gone for moderator, when flag passed."

    # and when accessed via history
    get :history, :id => node.node_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 0, "node #{node.node_id} version #{node.version} should not be present in the history for moderators when not passing flag."
    get :history, :id => node.node_id, :show_redactions => "true"
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 1, "node #{node.node_id} version #{node.version} should still be present in the history for moderators when passing flag."
  end

  # testing that if the moderator drops auth, he can't see the
  # redacted stuff any more.
  def test_redact_node_is_redacted
    node = nodes(:node_with_versions_v3)
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_node(node, redactions(:example))
    assert_response :success, "should be OK to redact old version as moderator."

    # re-auth as non-moderator
    basic_authorization(users(:public_user).email, "test")

    # check can't see the redacted data
    get :version, :id => node.node_id, :version => node.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API."

    # and when accessed via history
    get :history, :id => node.node_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 0, "redacted node #{node.node_id} version #{node.version} shouldn't be present in the history."
  end

  ##
  # test the unredaction of an old version of a node, while not being
  # authorised.
  def test_unredact_node_unauthorised
    node = nodes(:redacted_node_redacted_version)

    post :redact, :id => node.node_id, :version => node.version
    assert_response :unauthorized, "should need to be authenticated to unredact."
  end

  ##
  # test the unredaction of an old version of a node, while being
  # authorised as a normal user.
  def test_unredact_node_normal_user
    node = nodes(:redacted_node_redacted_version)
    basic_authorization(users(:public_user).email, "test")

    post :redact, :id => node.node_id, :version => node.version
    assert_response :forbidden, "should need to be moderator to unredact."
  end

  ##
  # test the unredaction of an old version of a node, while being
  # authorised as a moderator.
  def test_unredact_node_moderator
    node = nodes(:redacted_node_redacted_version)
    basic_authorization(users(:moderator_user).email, "test")

    post :redact, :id => node.node_id, :version => node.version
    assert_response :success, "should be OK to redact old version as moderator."

    # check moderator can now see the redacted data, when not
    # passing the aspecial flag
    get :version, :id => node.node_id, :version => node.version
    assert_response :success, "After unredaction, node should not be gone for moderator."

    # and when accessed via history
    get :history, :id => node.node_id
    assert_response :success, "Unredaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 1, "node #{node.node_id} version #{node.version} should now be present in the history for moderators without passing flag."

    basic_authorization(users(:normal_user).email, "test")

    # check normal user can now see the redacted data
    get :version, :id => node.node_id, :version => node.version
    assert_response :success, "After unredaction, node should not be gone for moderator."

    # and when accessed via history
    get :history, :id => node.node_id
    assert_response :success, "Unredaction shouldn't have stopped history working."
    assert_select "osm node[id='#{node.node_id}'][version='#{node.version}']", 1, "node #{node.node_id} version #{node.version} should now be present in the history for moderators without passing flag."
  end

  private

  def do_redact_node(node, redaction)
    get :version, :id => node.node_id, :version => node.version
    assert_response :success, "should be able to get version #{node.version} of node #{node.node_id}."

    # now redact it
    post :redact, :id => node.node_id, :version => node.version, :redaction => redaction.id
  end

  def check_current_version(node_id)
    # get the current version of the node
    current_node = with_controller(NodeController.new) do
      get :read, :id => node_id
      assert_response :success, "cant get current node #{node_id}"
      Node.from_xml(@response.body)
    end
    assert_not_nil current_node, "getting node #{node_id} returned nil"

    # get the "old" version of the node from the old_node interface
    get :version, :id => node_id, :version => current_node.version
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
    (1..16).map { |_i| letters[rand(letters.length)] }.join
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
