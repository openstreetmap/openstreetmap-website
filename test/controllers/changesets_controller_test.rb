require "test_helper"

class ChangesetsControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/changeset/create", :method => :put },
      { :controller => "changesets", :action => "create" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/upload", :method => :post },
      { :controller => "changesets", :action => "upload", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/download", :method => :get },
      { :controller => "changesets", :action => "download", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/expand_bbox", :method => :post },
      { :controller => "changesets", :action => "expand_bbox", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1", :method => :get },
      { :controller => "changesets", :action => "read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/subscribe", :method => :post },
      { :controller => "changesets", :action => "subscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/unsubscribe", :method => :post },
      { :controller => "changesets", :action => "unsubscribe", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1", :method => :put },
      { :controller => "changesets", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changeset/1/close", :method => :put },
      { :controller => "changesets", :action => "close", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/changesets", :method => :get },
      { :controller => "changesets", :action => "query" }
    )
    assert_routing(
      { :path => "/user/name/history", :method => :get },
      { :controller => "changesets", :action => "index", :display_name => "name" }
    )
    assert_routing(
      { :path => "/user/name/history/feed", :method => :get },
      { :controller => "changesets", :action => "feed", :display_name => "name", :format => :atom }
    )
    assert_routing(
      { :path => "/history/friends", :method => :get },
      { :controller => "changesets", :action => "index", :friends => true, :format => :html }
    )
    assert_routing(
      { :path => "/history/nearby", :method => :get },
      { :controller => "changesets", :action => "index", :nearby => true, :format => :html }
    )
    assert_routing(
      { :path => "/history", :method => :get },
      { :controller => "changesets", :action => "index" }
    )
    assert_routing(
      { :path => "/history/feed", :method => :get },
      { :controller => "changesets", :action => "feed", :format => :atom }
    )
  end

  # -----------------------
  # Test simple changeset creation
  # -----------------------

  def test_create
    basic_authorization create(:user, :data_public => false).email, "test"
    # Create the first user's changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_require_public_data

    basic_authorization create(:user).email, "test"
    # Create the first user's changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml

    assert_response :success, "Creation of changeset did not return sucess status"
    newid = @response.body.to_i

    # check end time, should be an hour ahead of creation time
    cs = Changeset.find(newid)
    duration = cs.closed_at - cs.created_at
    # the difference can either be a rational, or a floating point number
    # of seconds, depending on the code path taken :-(
    if duration.class == Rational
      assert_equal Rational(1, 24), duration, "initial idle timeout should be an hour (#{cs.created_at} -> #{cs.closed_at})"
    else
      # must be number of seconds...
      assert_equal 3600, duration.round, "initial idle timeout should be an hour (#{cs.created_at} -> #{cs.closed_at})"
    end

    # checks if uploader was subscribed
    assert_equal 1, cs.subscribers.length
  end

  def test_create_invalid
    basic_authorization create(:user, :data_public => false).email, "test"
    xml = "<osm><changeset></osm>"
    put :create, :body => xml
    assert_require_public_data

    ## Try the public user
    basic_authorization create(:user).email, "test"
    xml = "<osm><changeset></osm>"
    put :create, :body => xml
    assert_response :bad_request, "creating a invalid changeset should fail"
  end

  def test_create_invalid_no_content
    ## First check with no auth
    put :create
    assert_response :unauthorized, "shouldn't be able to create a changeset with no auth"

    ## Now try to with a non-public user
    basic_authorization create(:user, :data_public => false).email, "test"
    put :create
    assert_require_public_data

    ## Try an inactive user
    basic_authorization create(:user, :pending).email, "test"
    put :create
    assert_inactive_user

    ## Now try to use a normal user
    basic_authorization create(:user).email, "test"
    put :create
    assert_response :bad_request, "creating a changeset with no content should fail"
  end

  def test_create_wrong_method
    basic_authorization create(:user).email, "test"
    get :create
    assert_response :method_not_allowed
    post :create
    assert_response :method_not_allowed
  end

  ##
  # check that the changeset can be read and returns the correct
  # document structure.
  def test_read
    changeset_id = create(:changeset).id

    get :read, :params => { :id => changeset_id }
    assert_response :success, "cannot get first changeset"

    assert_select "osm[version='#{API_VERSION}'][generator='OpenStreetMap server']", 1
    assert_select "osm>changeset[id='#{changeset_id}']", 1
    assert_select "osm>changeset>discussion", 0

    get :read, :params => { :id => changeset_id, :include_discussion => true }
    assert_response :success, "cannot get first changeset with comments"

    assert_select "osm[version='#{API_VERSION}'][generator='OpenStreetMap server']", 1
    assert_select "osm>changeset[id='#{changeset_id}']", 1
    assert_select "osm>changeset>discussion", 1
    assert_select "osm>changeset>discussion>comment", 0

    changeset_id = create(:changeset, :closed).id
    create_list(:changeset_comment, 3, :changeset_id => changeset_id)

    get :read, :params => { :id => changeset_id, :include_discussion => true }
    assert_response :success, "cannot get closed changeset with comments"

    assert_select "osm[version='#{API_VERSION}'][generator='OpenStreetMap server']", 1
    assert_select "osm>changeset[id='#{changeset_id}']", 1
    assert_select "osm>changeset>discussion", 1
    assert_select "osm>changeset>discussion>comment", 3
  end

  ##
  # check that a changeset that doesn't exist returns an appropriate message
  def test_read_not_found
    [0, -32, 233455644, "afg", "213"].each do |id|
      begin
        get :read, :params => { :id => id }
        assert_response :not_found, "should get a not found"
      rescue ActionController::UrlGenerationError => ex
        assert_match(/No route matches/, ex.to_s)
      end
    end
  end

  ##
  # test that the user who opened a change can close it
  def test_close
    private_user = create(:user, :data_public => false)
    private_changeset = create(:changeset, :user => private_user)
    user = create(:user)
    changeset = create(:changeset, :user => user)

    ## Try without authentication
    put :close, :params => { :id => changeset.id }
    assert_response :unauthorized

    ## Try using the non-public user
    basic_authorization private_user.email, "test"
    put :close, :params => { :id => private_changeset.id }
    assert_require_public_data

    ## The try with the public user
    basic_authorization user.email, "test"

    cs_id = changeset.id
    put :close, :params => { :id => cs_id }
    assert_response :success

    # test that it really is closed now
    cs = Changeset.find(cs_id)
    assert_not(cs.is_open?,
               "changeset should be closed now (#{cs.closed_at} > #{Time.now.getutc}.")
  end

  ##
  # test that a different user can't close another user's changeset
  def test_close_invalid
    user = create(:user)
    changeset = create(:changeset)

    basic_authorization user.email, "test"

    put :close, :params => { :id => changeset.id }
    assert_response :conflict
    assert_equal "The user doesn't own that changeset", @response.body
  end

  ##
  # test that you can't close using another method
  def test_close_method_invalid
    user = create(:user)
    changeset = create(:changeset, :user => user)

    basic_authorization user.email, "test"

    get :close, :params => { :id => changeset.id }
    assert_response :method_not_allowed

    post :close, :params => { :id => changeset.id }
    assert_response :method_not_allowed
  end

  ##
  # check that you can't close a changeset that isn't found
  def test_close_not_found
    cs_ids = [0, -132, "123"]

    # First try to do it with no auth
    cs_ids.each do |id|
      begin
        put :close, :params => { :id => id }
        assert_response :unauthorized, "Shouldn't be able close the non-existant changeset #{id}, when not authorized"
      rescue ActionController::UrlGenerationError => ex
        assert_match(/No route matches/, ex.to_s)
      end
    end

    # Now try with auth
    basic_authorization create(:user).email, "test"
    cs_ids.each do |id|
      begin
        put :close, :params => { :id => id }
        assert_response :not_found, "The changeset #{id} doesn't exist, so can't be closed"
      rescue ActionController::UrlGenerationError => ex
        assert_match(/No route matches/, ex.to_s)
      end
    end
  end

  ##
  # upload something simple, but valid and check that it can
  # be read back ok
  # Also try without auth and another user.
  def test_upload_simple_valid
    private_user = create(:user, :data_public => false)
    private_changeset = create(:changeset, :user => private_user)
    user = create(:user)
    changeset = create(:changeset, :user => user)

    node = create(:node)
    way = create(:way)
    relation = create(:relation)
    other_relation = create(:relation)
    # create some tags, since we test that they are removed later
    create(:node_tag, :node => node)
    create(:way_tag, :way => way)
    create(:relation_tag, :relation => relation)

    ## Try with no auth
    changeset_id = changeset.id

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset_id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :unauthorized,
                    "shouldn't be able to upload a simple valid diff to changeset: #{@response.body}"

    ## Now try with a private user
    basic_authorization private_user.email, "test"
    changeset_id = private_changeset.id

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset_id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :forbidden,
                    "can't upload a simple valid diff to changeset: #{@response.body}"

    ## Now try with the public user
    basic_authorization user.email, "test"
    changeset_id = changeset.id

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset_id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :success,
                    "can't upload a simple valid diff to changeset: #{@response.body}"

    # check that the changes made it into the database
    assert_equal 0, Node.find(node.id).tags.size, "node #{node.id} should now have no tags"
    assert_equal 0, Way.find(way.id).tags.size, "way #{way.id} should now have no tags"
    assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
  end

  ##
  # upload something which creates new objects using placeholders
  def test_upload_create_valid
    user = create(:user)
    changeset = create(:changeset, :user => user)
    node = create(:node)
    way = create(:way_with_nodes, :nodes_count => 2)
    relation = create(:relation)

    basic_authorization user.email, "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
         <tag k='foo' v='bar'/>
         <tag k='baz' v='bat'/>
        </node>
        <way id='-1' changeset='#{changeset.id}'>
         <nd ref='#{node.id}'/>
        </way>
       </create>
       <create>
        <relation id='-1' changeset='#{changeset.id}'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{relation.id}'/>
        </relation>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :success,
                    "can't upload a simple valid creation to changeset: #{@response.body}"

    # check the returned payload
    assert_select "diffResult[version='#{API_VERSION}'][generator='OpenStreetMap server']", 1
    assert_select "diffResult>node", 1
    assert_select "diffResult>way", 1
    assert_select "diffResult>relation", 1

    # inspect the response to find out what the new element IDs are
    doc = XML::Parser.string(@response.body).parse
    new_node_id = doc.find("//diffResult/node").first["new_id"].to_i
    new_way_id = doc.find("//diffResult/way").first["new_id"].to_i
    new_rel_id = doc.find("//diffResult/relation").first["new_id"].to_i

    # check the old IDs are all present and negative one
    assert_equal(-1, doc.find("//diffResult/node").first["old_id"].to_i)
    assert_equal(-1, doc.find("//diffResult/way").first["old_id"].to_i)
    assert_equal(-1, doc.find("//diffResult/relation").first["old_id"].to_i)

    # check the versions are present and equal one
    assert_equal 1, doc.find("//diffResult/node").first["new_version"].to_i
    assert_equal 1, doc.find("//diffResult/way").first["new_version"].to_i
    assert_equal 1, doc.find("//diffResult/relation").first["new_version"].to_i

    # check that the changes made it into the database
    assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
    assert_equal 0, Way.find(new_way_id).tags.size, "new way should have no tags"
    assert_equal 0, Relation.find(new_rel_id).tags.size, "new relation should have no tags"
  end

  ##
  # test a complex delete where we delete elements which rely on eachother
  # in the same transaction.
  def test_upload_delete
    changeset = create(:changeset)
    super_relation = create(:relation)
    used_relation = create(:relation)
    used_way = create(:way)
    used_node = create(:node)
    create(:relation_member, :relation => super_relation, :member => used_relation)
    create(:relation_member, :relation => super_relation, :member => used_way)
    create(:relation_member, :relation => super_relation, :member => used_node)

    basic_authorization changeset.user.display_name, "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << super_relation.to_xml_node
    delete << used_relation.to_xml_node
    delete << used_way.to_xml_node
    delete << used_node.to_xml_node

    # update the changeset to one that this user owns
    %w[node way relation].each do |type|
      delete.find("//osmChange/delete/#{type}").each do |n|
        n["changeset"] = changeset.id.to_s
      end
    end

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff.to_s
    assert_response :success,
                    "can't upload a deletion diff to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 1
    assert_select "diffResult>way", 1
    assert_select "diffResult>relation", 2

    # check that everything was deleted
    assert_equal false, Node.find(used_node.id).visible
    assert_equal false, Way.find(used_way.id).visible
    assert_equal false, Relation.find(super_relation.id).visible
    assert_equal false, Relation.find(used_relation.id).visible
  end

  ##
  # test uploading a delete with no lat/lon, as they are optional in
  # the osmChange spec.
  def test_upload_nolatlon_delete
    node = create(:node)
    changeset = create(:changeset)

    basic_authorization changeset.user.display_name, "test"
    diff = "<osmChange><delete><node id='#{node.id}' version='#{node.version}' changeset='#{changeset.id}'/></delete></osmChange>"

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :success,
                    "can't upload a deletion diff to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 1

    # check that everything was deleted
    assert_equal false, Node.find(node.id).visible
  end

  def test_repeated_changeset_create
    3.times do
      basic_authorization create(:user).email, "test"

      # create a temporary changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      assert_difference "Changeset.count", 1 do
        put :create, :body => xml
      end
      assert_response :success
    end
  end

  def test_upload_large_changeset
    basic_authorization create(:user).email, "test"

    # create a changeset
    put :create, :body => "<osm><changeset/></osm>"
    assert_response :success, "Should be able to create a changeset: #{@response.body}"
    changeset_id = @response.body.to_i

    # upload some widely-spaced nodes, spiralling positive and negative
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id='-1' lon='-20' lat='-10' changeset='#{changeset_id}'/>
        <node id='-10' lon='20'  lat='10' changeset='#{changeset_id}'/>
        <node id='-2' lon='-40' lat='-20' changeset='#{changeset_id}'/>
        <node id='-11' lon='40'  lat='20' changeset='#{changeset_id}'/>
        <node id='-3' lon='-60' lat='-30' changeset='#{changeset_id}'/>
        <node id='-12' lon='60'  lat='30' changeset='#{changeset_id}'/>
        <node id='-4' lon='-80' lat='-40' changeset='#{changeset_id}'/>
        <node id='-13' lon='80'  lat='40' changeset='#{changeset_id}'/>
        <node id='-5' lon='-100' lat='-50' changeset='#{changeset_id}'/>
        <node id='-14' lon='100'  lat='50' changeset='#{changeset_id}'/>
        <node id='-6' lon='-120' lat='-60' changeset='#{changeset_id}'/>
        <node id='-15' lon='120'  lat='60' changeset='#{changeset_id}'/>
        <node id='-7' lon='-140' lat='-70' changeset='#{changeset_id}'/>
        <node id='-16' lon='140'  lat='70' changeset='#{changeset_id}'/>
        <node id='-8' lon='-160' lat='-80' changeset='#{changeset_id}'/>
        <node id='-17' lon='160'  lat='80' changeset='#{changeset_id}'/>
        <node id='-9' lon='-179.9' lat='-89.9' changeset='#{changeset_id}'/>
        <node id='-18' lon='179.9'  lat='89.9' changeset='#{changeset_id}'/>
       </create>
      </osmChange>
CHANGESET

    # upload it, which used to cause an error like "PGError: ERROR:
    # integer out of range" (bug #2152). but shouldn't any more.
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :success,
                    "can't upload a spatially-large diff to changeset: #{@response.body}"

    # check that the changeset bbox is within bounds
    cs = Changeset.find(changeset_id)
    assert cs.min_lon >= -180 * GeoRecord::SCALE, "Minimum longitude (#{cs.min_lon / GeoRecord::SCALE}) should be >= -180 to be valid."
    assert cs.max_lon <= 180 * GeoRecord::SCALE, "Maximum longitude (#{cs.max_lon / GeoRecord::SCALE}) should be <= 180 to be valid."
    assert cs.min_lat >= -90 * GeoRecord::SCALE, "Minimum latitude (#{cs.min_lat / GeoRecord::SCALE}) should be >= -90 to be valid."
    assert cs.max_lat <= 90 * GeoRecord::SCALE, "Maximum latitude (#{cs.max_lat / GeoRecord::SCALE}) should be <= 90 to be valid."
  end

  ##
  # test that deleting stuff in a transaction doesn't bypass the checks
  # to ensure that used elements are not deleted.
  def test_upload_delete_invalid
    changeset = create(:changeset)
    relation = create(:relation)
    other_relation = create(:relation)
    used_way = create(:way)
    used_node = create(:node)
    create(:relation_member, :relation => relation, :member => used_way)
    create(:relation_member, :relation => relation, :member => used_node)

    basic_authorization changeset.user.email, "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << other_relation.to_xml_node
    delete << used_way.to_xml_node
    delete << used_node.to_xml_node

    # update the changeset to one that this user owns
    %w[node way relation].each do |type|
      delete.find("//osmChange/delete/#{type}").each do |n|
        n["changeset"] = changeset.id.to_s
      end
    end

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff.to_s
    assert_response :precondition_failed,
                    "shouldn't be able to upload a invalid deletion diff: #{@response.body}"
    assert_equal "Precondition failed: Way #{used_way.id} is still used by relations #{relation.id}.", @response.body

    # check that nothing was, in fact, deleted
    assert_equal true, Node.find(used_node.id).visible
    assert_equal true, Way.find(used_way.id).visible
    assert_equal true, Relation.find(relation.id).visible
    assert_equal true, Relation.find(other_relation.id).visible
  end

  ##
  # test that a conditional delete of an in use object works.
  def test_upload_delete_if_unused
    changeset = create(:changeset)
    super_relation = create(:relation)
    used_relation = create(:relation)
    used_way = create(:way)
    used_node = create(:node)
    create(:relation_member, :relation => super_relation, :member => used_relation)
    create(:relation_member, :relation => super_relation, :member => used_way)
    create(:relation_member, :relation => super_relation, :member => used_node)

    basic_authorization changeset.user.email, "test"

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete["if-unused"] = ""
    delete << used_relation.to_xml_node
    delete << used_way.to_xml_node
    delete << used_node.to_xml_node

    # update the changeset to one that this user owns
    %w[node way relation].each do |type|
      delete.find("//osmChange/delete/#{type}").each do |n|
        n["changeset"] = changeset.id.to_s
      end
    end

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff.to_s
    assert_response :success,
                    "can't do a conditional delete of in use objects: #{@response.body}"

    # check the returned payload
    assert_select "diffResult[version='#{API_VERSION}'][generator='OpenStreetMap server']", 1
    assert_select "diffResult>node", 1
    assert_select "diffResult>way", 1
    assert_select "diffResult>relation", 1

    # parse the response
    doc = XML::Parser.string(@response.body).parse

    # check the old IDs are all present and what we expect
    assert_equal used_node.id, doc.find("//diffResult/node").first["old_id"].to_i
    assert_equal used_way.id, doc.find("//diffResult/way").first["old_id"].to_i
    assert_equal used_relation.id, doc.find("//diffResult/relation").first["old_id"].to_i

    # check the new IDs are all present and unchanged
    assert_equal used_node.id, doc.find("//diffResult/node").first["new_id"].to_i
    assert_equal used_way.id, doc.find("//diffResult/way").first["new_id"].to_i
    assert_equal used_relation.id, doc.find("//diffResult/relation").first["new_id"].to_i

    # check the new versions are all present and unchanged
    assert_equal used_node.version, doc.find("//diffResult/node").first["new_version"].to_i
    assert_equal used_way.version, doc.find("//diffResult/way").first["new_version"].to_i
    assert_equal used_relation.version, doc.find("//diffResult/relation").first["new_version"].to_i

    # check that nothing was, in fact, deleted
    assert_equal true, Node.find(used_node.id).visible
    assert_equal true, Way.find(used_way.id).visible
    assert_equal true, Relation.find(used_relation.id).visible
  end

  ##
  # upload an element with a really long tag value
  def test_upload_invalid_too_long_tag
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
         <tag k='foo' v='#{'x' * 256}'/>
        </node>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shoudln't be able to upload too long a tag to changeset: #{@response.body}"
  end

  ##
  # upload something which creates new objects and inserts them into
  # existing containers using placeholders.
  def test_upload_complex
    way = create(:way)
    node = create(:node)
    relation = create(:relation)
    create(:way_node, :way => way, :node => node)

    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
         <tag k='foo' v='bar'/>
         <tag k='baz' v='bat'/>
        </node>
       </create>
       <modify>
        <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
         <nd ref='-1'/>
         <nd ref='#{node.id}'/>
        </way>
        <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='-1'/>
         <member type='relation' role='some' ref='#{relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :success,
                    "can't upload a complex diff to changeset: #{@response.body}"

    # check the returned payload
    assert_select "diffResult[version='#{API_VERSION}'][generator='#{GENERATOR}']", 1
    assert_select "diffResult>node", 1
    assert_select "diffResult>way", 1
    assert_select "diffResult>relation", 1

    # inspect the response to find out what the new element IDs are
    doc = XML::Parser.string(@response.body).parse
    new_node_id = doc.find("//diffResult/node").first["new_id"].to_i

    # check that the changes made it into the database
    assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
    assert_equal [new_node_id, node.id], Way.find(way.id).nds, "way nodes should match"
    Relation.find(relation.id).members.each do |type, id, _role|
      assert_equal new_node_id, id, "relation should contain new node" if type == "node"
    end
  end

  ##
  # create a diff which references several changesets, which should cause
  # a rollback and none of the diff gets committed
  def test_upload_invalid_changesets
    changeset = create(:changeset)
    other_changeset = create(:changeset, :user => changeset.user)
    node = create(:node)
    way = create(:way)
    relation = create(:relation)
    other_relation = create(:relation)

    basic_authorization changeset.user.email, "test"

    # simple diff to create a node way and relation using placeholders
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
       <create>
        <node id='-1' lon='0' lat='0' changeset='#{other_changeset.id}'>
         <tag k='foo' v='bar'/>
         <tag k='baz' v='bat'/>
        </node>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :conflict,
                    "uploading a diff with multiple changesets should have failed"

    # check that objects are unmodified
    assert_nodes_are_equal(node, Node.find(node.id))
    assert_ways_are_equal(way, Way.find(way.id))
    assert_relations_are_equal(relation, Relation.find(relation.id))
  end

  ##
  # upload multiple versions of the same element in the same diff.
  def test_upload_multiple_valid
    node = create(:node)
    changeset = create(:changeset)
    basic_authorization changeset.user.email, "test"

    # change the location of a node multiple times, each time referencing
    # the last version. doesn't this depend on version numbers being
    # sequential?
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <node id='#{node.id}' lon='1' lat='0' changeset='#{changeset.id}' version='2'/>
        <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='3'/>
        <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset.id}' version='4'/>
        <node id='#{node.id}' lon='2' lat='2' changeset='#{changeset.id}' version='5'/>
        <node id='#{node.id}' lon='3' lat='2' changeset='#{changeset.id}' version='6'/>
        <node id='#{node.id}' lon='3' lat='3' changeset='#{changeset.id}' version='7'/>
        <node id='#{node.id}' lon='9' lat='9' changeset='#{changeset.id}' version='8'/>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :success,
                    "can't upload multiple versions of an element in a diff: #{@response.body}"

    # check the response is well-formed. its counter-intuitive, but the
    # API will return multiple elements with the same ID and different
    # version numbers for each change we made.
    assert_select "diffResult>node", 8
  end

  ##
  # upload multiple versions of the same element in the same diff, but
  # keep the version numbers the same.
  def test_upload_multiple_duplicate
    node = create(:node)
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :conflict,
                    "shouldn't be able to upload the same element twice in a diff: #{@response.body}"
  end

  ##
  # try to upload some elements without specifying the version
  def test_upload_missing_version
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
       <node id='1' lon='1' lat='1' changeset='#{changeset.id}'/>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shouldn't be able to upload an element without version: #{@response.body}"
  end

  ##
  # try to upload with commands other than create, modify, or delete
  def test_action_upload_invalid
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
        <ping>
         <node id='1' lon='1' lat='1' changeset='#{changeset.id}' />
        </ping>
      </osmChange>
CHANGESET
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request, "Shouldn't be able to upload a diff with the action ping"
    assert_equal @response.body, "Unknown action ping, choices are create, modify, delete"
  end

  ##
  # upload a valid changeset which has a mixture of whitespace
  # to check a bug reported by ivansanchez (#1565).
  def test_upload_whitespace_valid
    changeset = create(:changeset)
    node = create(:node)
    way = create(:way_with_nodes, :nodes_count => 2)
    relation = create(:relation)
    other_relation = create(:relation)
    create(:relation_tag, :relation => relation)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify><node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}'
        version='1'></node>
        <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='2'><tag k='k' v='v'/></node></modify>
       <modify>
       <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'><member
         type='way' role='some' ref='#{way.id}'/><member
          type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify></osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :success,
                    "can't upload a valid diff with whitespace variations to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 2
    assert_select "diffResult>relation", 1

    # check that the changes made it into the database
    assert_equal 1, Node.find(node.id).tags.size, "node #{node.id} should now have one tag"
    assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
  end

  ##
  # test that a placeholder can be reused within the same upload.
  def test_upload_reuse_placeholder_valid
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
         <tag k="foo" v="bar"/>
        </node>
       </create>
       <modify>
        <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
       </modify>
       <delete>
        <node id='-1' lon='2' lat='2' changeset='#{changeset.id}' version='2'/>
       </delete>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :success,
                    "can't upload a valid diff with re-used placeholders to changeset: #{@response.body}"

    # check the response is well-formed
    assert_select "diffResult>node", 3
    assert_select "diffResult>node[old_id='-1']", 3
  end

  ##
  # test what happens if a diff upload re-uses placeholder IDs in an
  # illegal way.
  def test_upload_placeholder_invalid
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
        <node id='-1' lon='2' lat='2' changeset='#{changeset.id}' version='2'/>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shouldn't be able to re-use placeholder IDs"
  end

  ##
  # test that uploading a way referencing invalid placeholders gives a
  # proper error, not a 500.
  def test_upload_placeholder_invalid_way
    changeset = create(:changeset)
    way = create(:way)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id="-1" lon="0" lat="0" changeset="#{changeset.id}" version="1"/>
        <node id="-2" lon="1" lat="1" changeset="#{changeset.id}" version="1"/>
        <node id="-3" lon="2" lat="2" changeset="#{changeset.id}" version="1"/>
        <way id="-1" changeset="#{changeset.id}" version="1">
         <nd ref="-1"/>
         <nd ref="-2"/>
         <nd ref="-3"/>
         <nd ref="-4"/>
        </way>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder node not found for reference -4 in way -1", @response.body

    # the same again, but this time use an existing way
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id="-1" lon="0" lat="0" changeset="#{changeset.id}" version="1"/>
        <node id="-2" lon="1" lat="1" changeset="#{changeset.id}" version="1"/>
        <node id="-3" lon="2" lat="2" changeset="#{changeset.id}" version="1"/>
        <way id="#{way.id}" changeset="#{changeset.id}" version="1">
         <nd ref="-1"/>
         <nd ref="-2"/>
         <nd ref="-3"/>
         <nd ref="-4"/>
        </way>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder node not found for reference -4 in way #{way.id}", @response.body
  end

  ##
  # test that uploading a relation referencing invalid placeholders gives a
  # proper error, not a 500.
  def test_upload_placeholder_invalid_relation
    changeset = create(:changeset)
    relation = create(:relation)

    basic_authorization changeset.user.email, "test"

    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id="-1" lon="0" lat="0" changeset="#{changeset.id}" version="1"/>
        <node id="-2" lon="1" lat="1" changeset="#{changeset.id}" version="1"/>
        <node id="-3" lon="2" lat="2" changeset="#{changeset.id}" version="1"/>
        <relation id="-1" changeset="#{changeset.id}" version="1">
         <member type="node" role="foo" ref="-1"/>
         <member type="node" role="foo" ref="-2"/>
         <member type="node" role="foo" ref="-3"/>
         <member type="node" role="foo" ref="-4"/>
        </relation>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder Node not found for reference -4 in relation -1.", @response.body

    # the same again, but this time use an existing relation
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <create>
        <node id="-1" lon="0" lat="0" changeset="#{changeset.id}" version="1"/>
        <node id="-2" lon="1" lat="1" changeset="#{changeset.id}" version="1"/>
        <node id="-3" lon="2" lat="2" changeset="#{changeset.id}" version="1"/>
        <relation id="#{relation.id}" changeset="#{changeset.id}" version="1">
         <member type="node" role="foo" ref="-1"/>
         <member type="node" role="foo" ref="-2"/>
         <member type="node" role="foo" ref="-3"/>
         <member type="way" role="bar" ref="-1"/>
        </relation>
       </create>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset.id }, :body => diff
    assert_response :bad_request,
                    "shouldn't be able to use invalid placeholder IDs"
    assert_equal "Placeholder Way not found for reference -1 in relation #{relation.id}.", @response.body
  end

  ##
  # test what happens if a diff is uploaded containing only a node
  # move.
  def test_upload_node_move
    basic_authorization create(:user).email, "test"

    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_response :success
    changeset_id = @response.body.to_i

    old_node = create(:node, :lat => 1, :lon => 1)

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    modify = XML::Node.new "modify"
    xml_old_node = old_node.to_xml_node
    xml_old_node["lat"] = 2.0.to_s
    xml_old_node["lon"] = 2.0.to_s
    xml_old_node["changeset"] = changeset_id.to_s
    modify << xml_old_node
    diff.root << modify

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff.to_s
    assert_response :success,
                    "diff should have uploaded OK"

    # check the bbox
    changeset = Changeset.find(changeset_id)
    assert_equal 1 * GeoRecord::SCALE, changeset.min_lon, "min_lon should be 1 degree"
    assert_equal 2 * GeoRecord::SCALE, changeset.max_lon, "max_lon should be 2 degrees"
    assert_equal 1 * GeoRecord::SCALE, changeset.min_lat, "min_lat should be 1 degree"
    assert_equal 2 * GeoRecord::SCALE, changeset.max_lat, "max_lat should be 2 degrees"
  end

  ##
  # test what happens if a diff is uploaded adding a node to a way.
  def test_upload_way_extend
    basic_authorization create(:user).email, "test"

    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_response :success
    changeset_id = @response.body.to_i

    old_way = create(:way)
    create(:way_node, :way => old_way, :node => create(:node, :lat => 1, :lon => 1))

    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    modify = XML::Node.new "modify"
    xml_old_way = old_way.to_xml_node
    nd_ref = XML::Node.new "nd"
    nd_ref["ref"] = create(:node, :lat => 3, :lon => 3).id.to_s
    xml_old_way << nd_ref
    xml_old_way["changeset"] = changeset_id.to_s
    modify << xml_old_way
    diff.root << modify

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff.to_s
    assert_response :success,
                    "diff should have uploaded OK"

    # check the bbox
    changeset = Changeset.find(changeset_id)
    assert_equal 1 * GeoRecord::SCALE, changeset.min_lon, "min_lon should be 1 degree"
    assert_equal 3 * GeoRecord::SCALE, changeset.max_lon, "max_lon should be 3 degrees"
    assert_equal 1 * GeoRecord::SCALE, changeset.min_lat, "min_lat should be 1 degree"
    assert_equal 3 * GeoRecord::SCALE, changeset.max_lat, "max_lat should be 3 degrees"
  end

  ##
  # test for more issues in #1568
  def test_upload_empty_invalid
    changeset = create(:changeset)

    basic_authorization changeset.user.email, "test"

    ["<osmChange/>",
     "<osmChange></osmChange>",
     "<osmChange><modify/></osmChange>",
     "<osmChange><modify></modify></osmChange>"].each do |diff|
      # upload it
      post :upload, :params => { :id => changeset.id }, :body => diff
      assert_response(:success, "should be able to upload " \
                      "empty changeset: " + diff)
    end
  end

  ##
  # test that the X-Error-Format header works to request XML errors
  def test_upload_xml_errors
    changeset = create(:changeset)
    node = create(:node)
    create(:relation_member, :member => node)

    basic_authorization changeset.user.email, "test"

    # try and delete a node that is in use
    diff = XML::Document.new
    diff.root = XML::Node.new "osmChange"
    delete = XML::Node.new "delete"
    diff.root << delete
    delete << node.to_xml_node

    # upload it
    error_format "xml"
    post :upload, :params => { :id => changeset.id }, :body => diff.to_s
    assert_response :success,
                    "failed to return error in XML format"

    # check the returned payload
    assert_select "osmError[version='#{API_VERSION}'][generator='OpenStreetMap server']", 1
    assert_select "osmError>status", 1
    assert_select "osmError>message", 1
  end

  ##
  # when we make some simple changes we get the same changes back from the
  # diff download.
  def test_diff_download_simple
    node = create(:node)

    ## First try with a non-public user, which should get a forbidden
    basic_authorization create(:user, :data_public => false).email, "test"

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_response :forbidden

    ## Now try with a normal user
    basic_authorization create(:user).email, "test"

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_response :success
    changeset_id = @response.body.to_i

    # add a diff to it
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
        <node id='#{node.id}' lon='1' lat='0' changeset='#{changeset_id}' version='2'/>
        <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset_id}' version='3'/>
        <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset_id}' version='4'/>
        <node id='#{node.id}' lon='2' lat='2' changeset='#{changeset_id}' version='5'/>
        <node id='#{node.id}' lon='3' lat='2' changeset='#{changeset_id}' version='6'/>
        <node id='#{node.id}' lon='3' lat='3' changeset='#{changeset_id}' version='7'/>
        <node id='#{node.id}' lon='9' lat='9' changeset='#{changeset_id}' version='8'/>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :success,
                    "can't upload multiple versions of an element in a diff: #{@response.body}"

    get :download, :params => { :id => changeset_id }
    assert_response :success

    assert_select "osmChange", 1
    assert_select "osmChange>modify", 8
    assert_select "osmChange>modify>node", 8
  end

  ##
  # culled this from josm to ensure that nothing in the way that josm
  # is formatting the request is causing it to fail.
  #
  # NOTE: the error turned out to be something else completely!
  def test_josm_upload
    basic_authorization create(:user).email, "test"

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_response :success
    changeset_id = @response.body.to_i

    diff = <<OSMFILE.strip_heredoc
      <osmChange version="0.6" generator="JOSM">
      <create version="0.6" generator="JOSM">
        <node id='-1' visible='true' changeset='#{changeset_id}' lat='51.49619982187321' lon='-0.18722061869438314' />
        <node id='-2' visible='true' changeset='#{changeset_id}' lat='51.496359883909605' lon='-0.18653093576241928' />
        <node id='-3' visible='true' changeset='#{changeset_id}' lat='51.49598132358285' lon='-0.18719613290981638' />
        <node id='-4' visible='true' changeset='#{changeset_id}' lat='51.4961591711078' lon='-0.18629015888084607' />
        <node id='-5' visible='true' changeset='#{changeset_id}' lat='51.49582126021711' lon='-0.18708186591517145' />
        <node id='-6' visible='true' changeset='#{changeset_id}' lat='51.49591018437858' lon='-0.1861432441734455' />
        <node id='-7' visible='true' changeset='#{changeset_id}' lat='51.49560784152179' lon='-0.18694719410005425' />
        <node id='-8' visible='true' changeset='#{changeset_id}' lat='51.49567389979617' lon='-0.1860289771788006' />
        <node id='-9' visible='true' changeset='#{changeset_id}' lat='51.49543761398892' lon='-0.186820684213126' />
        <way id='-10' action='modiy' visible='true' changeset='#{changeset_id}'>
          <nd ref='-1' />
          <nd ref='-2' />
          <nd ref='-3' />
          <nd ref='-4' />
          <nd ref='-5' />
          <nd ref='-6' />
          <nd ref='-7' />
          <nd ref='-8' />
          <nd ref='-9' />
          <tag k='highway' v='residential' />
          <tag k='name' v='Foobar Street' />
        </way>
      </create>
      </osmChange>
OSMFILE

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :success,
                    "can't upload a diff from JOSM: #{@response.body}"

    get :download, :params => { :id => changeset_id }
    assert_response :success

    assert_select "osmChange", 1
    assert_select "osmChange>create>node", 9
    assert_select "osmChange>create>way", 1
    assert_select "osmChange>create>way>nd", 9
    assert_select "osmChange>create>way>tag", 2
  end

  ##
  # when we make some complex changes we get the same changes back from the
  # diff download.
  def test_diff_download_complex
    node = create(:node)
    node2 = create(:node)
    way = create(:way)
    basic_authorization create(:user).email, "test"

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    put :create, :body => xml
    assert_response :success
    changeset_id = @response.body.to_i

    # add a diff to it
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <delete>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
       </delete>
       <create>
        <node id='-1' lon='9' lat='9' changeset='#{changeset_id}' version='0'/>
        <node id='-2' lon='8' lat='9' changeset='#{changeset_id}' version='0'/>
        <node id='-3' lon='7' lat='9' changeset='#{changeset_id}' version='0'/>
       </create>
       <modify>
        <node id='#{node2.id}' lon='20' lat='15' changeset='#{changeset_id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
         <nd ref='#{node2.id}'/>
         <nd ref='-1'/>
         <nd ref='-2'/>
         <nd ref='-3'/>
        </way>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post :upload, :params => { :id => changeset_id }, :body => diff
    assert_response :success,
                    "can't upload multiple versions of an element in a diff: #{@response.body}"

    get :download, :params => { :id => changeset_id }
    assert_response :success

    assert_select "osmChange", 1
    assert_select "osmChange>create", 3
    assert_select "osmChange>delete", 1
    assert_select "osmChange>modify", 2
    assert_select "osmChange>create>node", 3
    assert_select "osmChange>delete>node", 1
    assert_select "osmChange>modify>node", 1
    assert_select "osmChange>modify>way", 1
  end

  def test_changeset_download
    changeset = create(:changeset)
    node = create(:node, :with_history, :version => 1, :changeset => changeset)
    tag = create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 1))
    node2 = create(:node, :with_history, :version => 1, :changeset => changeset)
    _node3 = create(:node, :with_history, :deleted, :version => 1, :changeset => changeset)
    _relation = create(:relation, :with_history, :version => 1, :changeset => changeset)
    _relation2 = create(:relation, :with_history, :deleted, :version => 1, :changeset => changeset)

    get :download, :params => { :id => changeset.id }

    assert_response :success
    assert_template nil
    # print @response.body
    # FIXME: needs more assert_select tests
    assert_select "osmChange[version='#{API_VERSION}'][generator='#{GENERATOR}']" do
      assert_select "create", :count => 5
      assert_select "create>node[id='#{node.id}'][visible='#{node.visible?}'][version='#{node.version}']" do
        assert_select "tag[k='#{tag.k}'][v='#{tag.v}']"
      end
      assert_select "create>node[id='#{node2.id}']"
    end
  end

  ##
  # check that the bounding box of a changeset gets updated correctly
  # FIXME: This should really be moded to a integration test due to the with_controller
  def test_changeset_bbox
    way = create(:way)
    create(:way_node, :way => way, :node => create(:node, :lat => 3, :lon => 3))

    basic_authorization create(:user).email, "test"

    # create a new changeset
    xml = "<osm><changeset/></osm>"
    put :create, :body => xml
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    # add a single node to it
    with_controller(NodesController.new) do
      xml = "<osm><node lon='1' lat='2' changeset='#{changeset_id}'/></osm>"
      put :create, :body => xml
      assert_response :success, "Couldn't create node."
    end

    # get the bounding box back from the changeset
    get :read, :params => { :id => changeset_id }
    assert_response :success, "Couldn't read back changeset."
    assert_select "osm>changeset[min_lon='1.0000000']", 1
    assert_select "osm>changeset[max_lon='1.0000000']", 1
    assert_select "osm>changeset[min_lat='2.0000000']", 1
    assert_select "osm>changeset[max_lat='2.0000000']", 1

    # add another node to it
    with_controller(NodesController.new) do
      xml = "<osm><node lon='2' lat='1' changeset='#{changeset_id}'/></osm>"
      put :create, :body => xml
      assert_response :success, "Couldn't create second node."
    end

    # get the bounding box back from the changeset
    get :read, :params => { :id => changeset_id }
    assert_response :success, "Couldn't read back changeset for the second time."
    assert_select "osm>changeset[min_lon='1.0000000']", 1
    assert_select "osm>changeset[max_lon='2.0000000']", 1
    assert_select "osm>changeset[min_lat='1.0000000']", 1
    assert_select "osm>changeset[max_lat='2.0000000']", 1

    # add (delete) a way to it, which contains a point at (3,3)
    with_controller(WaysController.new) do
      xml = update_changeset(way.to_xml, changeset_id)
      put :delete, :params => { :id => way.id }, :body => xml.to_s
      assert_response :success, "Couldn't delete a way."
    end

    # get the bounding box back from the changeset
    get :read, :params => { :id => changeset_id }
    assert_response :success, "Couldn't read back changeset for the third time."
    assert_select "osm>changeset[min_lon='1.0000000']", 1
    assert_select "osm>changeset[max_lon='3.0000000']", 1
    assert_select "osm>changeset[min_lat='1.0000000']", 1
    assert_select "osm>changeset[max_lat='3.0000000']", 1
  end

  ##
  # test that the changeset :include method works as it should
  def test_changeset_include
    basic_authorization create(:user).display_name, "test"

    # create a new changeset
    put :create, :body => "<osm><changeset/></osm>"
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    # NOTE: the include method doesn't over-expand, like inserting
    # a real method does. this is because we expect the client to
    # know what it is doing!
    check_after_include(changeset_id, 1, 1, [1, 1, 1, 1])
    check_after_include(changeset_id, 3, 3, [1, 1, 3, 3])
    check_after_include(changeset_id, 4, 2, [1, 1, 4, 3])
    check_after_include(changeset_id, 2, 2, [1, 1, 4, 3])
    check_after_include(changeset_id, -1, -1, [-1, -1, 4, 3])
    check_after_include(changeset_id, -2, 5, [-2, -1, 4, 5])
  end

  ##
  # test that a not found, wrong method with the expand bbox works as expected
  def test_changeset_expand_bbox_error
    basic_authorization create(:user).display_name, "test"

    # create a new changeset
    xml = "<osm><changeset/></osm>"
    put :create, :body => xml
    assert_response :success, "Creating of changeset failed."
    changeset_id = @response.body.to_i

    lon = 58.2
    lat = -0.45

    # Try and put
    xml = "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    put :expand_bbox, :params => { :id => changeset_id }, :body => xml
    assert_response :method_not_allowed, "shouldn't be able to put a bbox expand"

    # Try to get the update
    xml = "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    get :expand_bbox, :params => { :id => changeset_id }, :body => xml
    assert_response :method_not_allowed, "shouldn't be able to get a bbox expand"

    # Try to use a hopefully missing changeset
    xml = "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    post :expand_bbox, :params => { :id => changeset_id + 13245 }, :body => xml
    assert_response :not_found, "shouldn't be able to do a bbox expand on a nonexistant changeset"
  end

  ##
  # test the query functionality of changesets
  def test_query
    private_user = create(:user, :data_public => false)
    private_user_changeset = create(:changeset, :user => private_user)
    private_user_closed_changeset = create(:changeset, :closed, :user => private_user)
    user = create(:user)
    changeset = create(:changeset, :user => user)
    closed_changeset = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 1, 1, 0, 0, 0), :closed_at => Time.utc(2008, 1, 2, 0, 0, 0))
    changeset2 = create(:changeset, :min_lat => 5 * GeoRecord::SCALE, :min_lon => 5 * GeoRecord::SCALE, :max_lat => 15 * GeoRecord::SCALE, :max_lon => 15 * GeoRecord::SCALE)
    changeset3 = create(:changeset, :min_lat => 4.5 * GeoRecord::SCALE, :min_lon => 4.5 * GeoRecord::SCALE, :max_lat => 5 * GeoRecord::SCALE, :max_lon => 5 * GeoRecord::SCALE)

    get :query, :params => { :bbox => "-10,-10, 10, 10" }
    assert_response :success, "can't get changesets in bbox"
    assert_changesets [changeset2, changeset3]

    get :query, :params => { :bbox => "4.5,4.5,4.6,4.6" }
    assert_response :success, "can't get changesets in bbox"
    assert_changesets [changeset3]

    # not found when looking for changesets of non-existing users
    get :query, :params => { :user => User.maximum(:id) + 1 }
    assert_response :not_found
    get :query, :params => { :display_name => " " }
    assert_response :not_found

    # can't get changesets of user 1 without authenticating
    get :query, :params => { :user => private_user.id }
    assert_response :not_found, "shouldn't be able to get changesets by non-public user (ID)"
    get :query, :params => { :display_name => private_user.display_name }
    assert_response :not_found, "shouldn't be able to get changesets by non-public user (name)"

    # but this should work
    basic_authorization private_user.email, "test"
    get :query, :params => { :user => private_user.id }
    assert_response :success, "can't get changesets by user ID"
    assert_changesets [private_user_changeset, private_user_closed_changeset]

    get :query, :params => { :display_name => private_user.display_name }
    assert_response :success, "can't get changesets by user name"
    assert_changesets [private_user_changeset, private_user_closed_changeset]

    # check that the correct error is given when we provide both UID and name
    get :query, :params => { :user => private_user.id,
                             :display_name => private_user.display_name }
    assert_response :bad_request, "should be a bad request to have both ID and name specified"

    get :query, :params => { :user => private_user.id, :open => true }
    assert_response :success, "can't get changesets by user and open"
    assert_changesets [private_user_changeset]

    get :query, :params => { :time => "2007-12-31" }
    assert_response :success, "can't get changesets by time-since"
    assert_changesets [private_user_changeset, private_user_closed_changeset, changeset, closed_changeset, changeset2, changeset3]

    get :query, :params => { :time => "2008-01-01T12:34Z" }
    assert_response :success, "can't get changesets by time-since with hour"
    assert_changesets [private_user_changeset, private_user_closed_changeset, changeset, closed_changeset, changeset2, changeset3]

    get :query, :params => { :time => "2007-12-31T23:59Z,2008-01-02T00:01Z" }
    assert_response :success, "can't get changesets by time-range"
    assert_changesets [closed_changeset]

    get :query, :params => { :open => "true" }
    assert_response :success, "can't get changesets by open-ness"
    assert_changesets [private_user_changeset, changeset, changeset2, changeset3]

    get :query, :params => { :closed => "true" }
    assert_response :success, "can't get changesets by closed-ness"
    assert_changesets [private_user_closed_changeset, closed_changeset]

    get :query, :params => { :closed => "true", :user => private_user.id }
    assert_response :success, "can't get changesets by closed-ness and user"
    assert_changesets [private_user_closed_changeset]

    get :query, :params => { :closed => "true", :user => user.id }
    assert_response :success, "can't get changesets by closed-ness and user"
    assert_changesets [closed_changeset]

    get :query, :params => { :changesets => "#{private_user_changeset.id},#{changeset.id},#{closed_changeset.id}" }
    assert_response :success, "can't get changesets by id (as comma-separated string)"
    assert_changesets [private_user_changeset, changeset, closed_changeset]

    get :query, :params => { :changesets => "" }
    assert_response :bad_request, "should be a bad request since changesets is empty"
  end

  ##
  # check that errors are returned if garbage is inserted
  # into query strings
  def test_query_invalid
    ["abracadabra!",
     "1,2,3,F",
     ";drop table users;"].each do |bbox|
      get :query, :params => { :bbox => bbox }
      assert_response :bad_request, "'#{bbox}' isn't a bbox"
    end

    ["now()",
     "00-00-00",
     ";drop table users;",
     ",",
     "-,-"].each do |time|
      get :query, :params => { :time => time }
      assert_response :bad_request, "'#{time}' isn't a valid time range"
    end

    ["me",
     "foobar",
     "-1",
     "0"].each do |uid|
      get :query, :params => { :user => uid }
      assert_response :bad_request, "'#{uid}' isn't a valid user ID"
    end
  end

  ##
  # check updating tags on a changeset
  def test_changeset_update
    private_user = create(:user, :data_public => false)
    private_changeset = create(:changeset, :user => private_user)
    user = create(:user)
    changeset = create(:changeset, :user => user)

    ## First try with a non-public user
    new_changeset = private_changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag["k"] = "tagtesting"
    new_tag["v"] = "valuetesting"
    new_changeset.find("//osm/changeset").first << new_tag

    # try without any authorization
    put :update, :params => { :id => private_changeset.id }, :body => new_changeset.to_s
    assert_response :unauthorized

    # try with the wrong authorization
    basic_authorization create(:user).email, "test"
    put :update, :params => { :id => private_changeset.id }, :body => new_changeset.to_s
    assert_response :conflict

    # now this should get an unauthorized
    basic_authorization private_user.email, "test"
    put :update, :params => { :id => private_changeset.id }, :body => new_changeset.to_s
    assert_require_public_data "user with their data non-public, shouldn't be able to edit their changeset"

    ## Now try with the public user
    create(:changeset_tag, :changeset => changeset)
    new_changeset = changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag["k"] = "tagtesting"
    new_tag["v"] = "valuetesting"
    new_changeset.find("//osm/changeset").first << new_tag

    # try without any authorization
    @request.env["HTTP_AUTHORIZATION"] = nil
    put :update, :params => { :id => changeset.id }, :body => new_changeset.to_s
    assert_response :unauthorized

    # try with the wrong authorization
    basic_authorization create(:user).email, "test"
    put :update, :params => { :id => changeset.id }, :body => new_changeset.to_s
    assert_response :conflict

    # now this should work...
    basic_authorization user.email, "test"
    put :update, :params => { :id => changeset.id }, :body => new_changeset.to_s
    assert_response :success

    assert_select "osm>changeset[id='#{changeset.id}']", 1
    assert_select "osm>changeset>tag", 2
    assert_select "osm>changeset>tag[k='tagtesting'][v='valuetesting']", 1
  end

  ##
  # check that a user different from the one who opened the changeset
  # can't modify it.
  def test_changeset_update_invalid
    basic_authorization create(:user).email, "test"

    changeset = create(:changeset)
    new_changeset = changeset.to_xml
    new_tag = XML::Node.new "tag"
    new_tag["k"] = "testing"
    new_tag["v"] = "testing"
    new_changeset.find("//osm/changeset").first << new_tag

    put :update, :params => { :id => changeset.id }, :body => new_changeset.to_s
    assert_response :conflict
  end

  ##
  # check that a changeset can contain a certain max number of changes.
  ## FIXME should be changed to an integration test due to the with_controller
  def test_changeset_limits
    basic_authorization create(:user).email, "test"

    # open a new changeset
    xml = "<osm><changeset/></osm>"
    put :create, :body => xml
    assert_response :success, "can't create a new changeset"
    cs_id = @response.body.to_i

    # start the counter just short of where the changeset should finish.
    offset = 10
    # alter the database to set the counter on the changeset directly,
    # otherwise it takes about 6 minutes to fill all of them.
    changeset = Changeset.find(cs_id)
    changeset.num_changes = Changeset::MAX_ELEMENTS - offset
    changeset.save!

    with_controller(NodesController.new) do
      # create a new node
      xml = "<osm><node changeset='#{cs_id}' lat='0.0' lon='0.0'/></osm>"
      put :create, :body => xml
      assert_response :success, "can't create a new node"
      node_id = @response.body.to_i

      get :read, :params => { :id => node_id }
      assert_response :success, "can't read back new node"
      node_doc = XML::Parser.string(@response.body).parse
      node_xml = node_doc.find("//osm/node").first

      # loop until we fill the changeset with nodes
      offset.times do |i|
        node_xml["lat"] = rand.to_s
        node_xml["lon"] = rand.to_s
        node_xml["version"] = (i + 1).to_s

        put :update, :params => { :id => node_id }, :body => node_doc.to_s
        assert_response :success, "attempt #{i} should have succeeded"
      end

      # trying again should fail
      node_xml["lat"] = rand.to_s
      node_xml["lon"] = rand.to_s
      node_xml["version"] = offset.to_s

      put :update, :params => { :id => node_id }, :body => node_doc.to_s
      assert_response :conflict, "final attempt should have failed"
    end

    changeset = Changeset.find(cs_id)
    assert_equal Changeset::MAX_ELEMENTS + 1, changeset.num_changes

    # check that the changeset is now closed as well
    assert_not(changeset.is_open?,
               "changeset should have been auto-closed by exceeding " \
               "element limit.")
  end

  ##
  # This should display the last 20 changesets closed
  def test_index
    get :index, :params => { :format => "html" }
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.all)
  end

  ##
  # This should display the last 20 changesets closed
  def test_index_xhr
    get :index, :params => { :format => "html" }, :xhr => true
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.all)
  end

  ##
  # This should display the last 20 changesets closed in a specific area
  def test_index_bbox
    get :index, :params => { :format => "html", :bbox => "4.5,4.5,5.5,5.5" }
    assert_response :success
    assert_template "history"
    assert_template :layout => "map"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :bbox => "4.5,4.5,5.5,5.5", :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where("min_lon < 55000000 and max_lon > 45000000 and min_lat < 55000000 and max_lat > 45000000"))
  end

  ##
  # Checks the display of the user changesets listing
  def test_index_user
    user = create(:user)
    create(:changeset, :user => user)
    create(:changeset, :closed, :user => user)

    get :index, :params => { :format => "html", :display_name => user.display_name }
    assert_response :success
    assert_template "history"

    get :index, :params => { :format => "html", :display_name => user.display_name, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(user.changesets)
  end

  ##
  # Checks the display of the user changesets listing for a private user
  def test_index_private_user
    private_user = create(:user, :data_public => false)
    create(:changeset, :user => private_user)
    create(:changeset, :closed, :user => private_user)

    get :index, :params => { :format => "html", :display_name => private_user.display_name }
    assert_response :success
    assert_template "history"

    get :index, :params => { :format => "html", :display_name => private_user.display_name, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.none)
  end

  ##
  # Check the not found of the index user changesets
  def test_index_user_not_found
    get :index, :params => { :format => "html", :display_name => "Some random user" }
    assert_response :not_found
    assert_template "users/no_such_user"

    get :index, :params => { :format => "html", :display_name => "Some random user", :list => "1" }, :xhr => true
    assert_response :not_found
    assert_template "users/no_such_user"
  end

  ##
  # Checks the display of the friends changesets listing
  def test_index_friends
    private_user = create(:user, :data_public => true)
    friend = create(:friend, :befriender => private_user)
    create(:changeset, :user => friend.befriendee)

    get :index, :params => { :friends => true }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => friend_changesets_path

    session[:user] = private_user.id

    get :index, :params => { :friends => true }
    assert_response :success
    assert_template "history"

    get :index, :params => { :friends => true, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where(:user => private_user.friend_users.identifiable))
  end

  ##
  # Checks the display of the nearby user changesets listing
  def test_index_nearby
    private_user = create(:user, :data_public => false, :home_lat => 51.1, :home_lon => 1.0)
    user = create(:user, :home_lat => 51.0, :home_lon => 1.0)
    create(:changeset, :user => user)

    get :index, :params => { :nearby => true }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => nearby_changesets_path

    session[:user] = private_user.id

    get :index, :params => { :nearby => true }
    assert_response :success
    assert_template "history"

    get :index, :params => { :nearby => true, :list => "1" }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where(:user => user.nearby))
  end

  ##
  # Check that we can't request later pages of the changesets index
  def test_index_max_id
    get :index, :params => { :format => "html", :max_id => 4 }, :xhr => true
    assert_response :success
    assert_template "history"
    assert_template :layout => "xhr"
    assert_select "h2", :text => "Changesets", :count => 1

    get :index, :params => { :format => "html", :list => "1", :max_id => 4 }, :xhr => true
    assert_response :success
    assert_template "index"

    check_index_result(Changeset.where("id <= 4"))
  end

  ##
  # Check that a list with a next page link works
  def test_index_more
    create_list(:changeset, 50)

    get :index, :params => { :format => "html" }
    assert_response :success

    get :index, :params => { :format => "html" }, :xhr => true
    assert_response :success
  end

  ##
  # This should display the last 20 non-empty changesets
  def test_feed
    changeset = create(:changeset, :num_changes => 1)
    create(:changeset_tag, :changeset => changeset)
    create(:changeset_tag, :changeset => changeset, :k => "website", :v => "http://example.com/")
    closed_changeset = create(:changeset, :closed, :num_changes => 1)
    _empty_changeset = create(:changeset, :num_changes => 0)

    get :feed, :params => { :format => :atom }
    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.content_type

    check_feed_result([changeset, closed_changeset])
  end

  ##
  # This should display the last 20 changesets closed in a specific area
  def test_feed_bbox
    changeset = create(:changeset, :num_changes => 1, :min_lat => 5 * GeoRecord::SCALE, :min_lon => 5 * GeoRecord::SCALE, :max_lat => 5 * GeoRecord::SCALE, :max_lon => 5 * GeoRecord::SCALE)
    create(:changeset_tag, :changeset => changeset)
    create(:changeset_tag, :changeset => changeset, :k => "website", :v => "http://example.com/")
    closed_changeset = create(:changeset, :closed, :num_changes => 1, :min_lat => 5 * GeoRecord::SCALE, :min_lon => 5 * GeoRecord::SCALE, :max_lat => 5 * GeoRecord::SCALE, :max_lon => 5 * GeoRecord::SCALE)
    _elsewhere_changeset = create(:changeset, :num_changes => 1, :min_lat => -5 * GeoRecord::SCALE, :min_lon => -5 * GeoRecord::SCALE, :max_lat => -5 * GeoRecord::SCALE, :max_lon => -5 * GeoRecord::SCALE)
    _empty_changeset = create(:changeset, :num_changes => 0, :min_lat => -5 * GeoRecord::SCALE, :min_lon => -5 * GeoRecord::SCALE, :max_lat => -5 * GeoRecord::SCALE, :max_lon => -5 * GeoRecord::SCALE)

    get :feed, :params => { :format => :atom, :bbox => "4.5,4.5,5.5,5.5" }
    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.content_type

    check_feed_result([changeset, closed_changeset])
  end

  ##
  # Checks the display of the user changesets feed
  def test_feed_user
    user = create(:user)
    changesets = create_list(:changeset, 3, :user => user, :num_changes => 4)
    create(:changeset_tag, :changeset => changesets[1])
    create(:changeset_tag, :changeset => changesets[1], :k => "website", :v => "http://example.com/")
    _other_changeset = create(:changeset)

    get :feed, :params => { :format => :atom, :display_name => user.display_name }

    assert_response :success
    assert_template "index"
    assert_equal "application/atom+xml", response.content_type

    check_feed_result(changesets)
  end

  ##
  # Check the not found of the user changesets feed
  def test_feed_user_not_found
    get :feed, :params => { :format => "atom", :display_name => "Some random user" }
    assert_response :not_found
  end

  ##
  # Check that we can't request later pages of the changesets feed
  def test_feed_max_id
    get :feed, :params => { :format => "atom", :max_id => 100 }
    assert_response :redirect
    assert_redirected_to :action => :feed
  end

  ##
  # check that the changeset download for a changeset with a redacted
  # element in it doesn't contain that element.
  def test_diff_download_redacted
    changeset = create(:changeset)
    node = create(:node, :with_history, :version => 2, :changeset => changeset)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get :download, :params => { :id => changeset.id }
    assert_response :success

    assert_select "osmChange", 1
    # this changeset contains the node in versions 1 & 2, but 1 should
    # be hidden.
    assert_select "osmChange node[id='#{node.id}']", 1
    assert_select "osmChange node[id='#{node.id}'][version='1']", 0
  end

  ##
  # test subscribe success
  def test_subscribe_success
    basic_authorization create(:user).email, "test"
    changeset = create(:changeset, :closed)

    assert_difference "changeset.subscribers.count", 1 do
      post :subscribe, :params => { :id => changeset.id }
    end
    assert_response :success

    # not closed changeset
    changeset = create(:changeset)
    assert_difference "changeset.subscribers.count", 1 do
      post :subscribe, :params => { :id => changeset.id }
    end
    assert_response :success
  end

  ##
  # test subscribe fail
  def test_subscribe_fail
    user = create(:user)

    # unauthorized
    changeset = create(:changeset, :closed)
    assert_no_difference "changeset.subscribers.count" do
      post :subscribe, :params => { :id => changeset.id }
    end
    assert_response :unauthorized

    basic_authorization user.email, "test"

    # bad changeset id
    assert_no_difference "changeset.subscribers.count" do
      post :subscribe, :params => { :id => 999111 }
    end
    assert_response :not_found

    # trying to subscribe when already subscribed
    changeset = create(:changeset, :closed)
    changeset.subscribers.push(user)
    assert_no_difference "changeset.subscribers.count" do
      post :subscribe, :params => { :id => changeset.id }
    end
    assert_response :conflict
  end

  ##
  # test unsubscribe success
  def test_unsubscribe_success
    user = create(:user)
    basic_authorization user.email, "test"
    changeset = create(:changeset, :closed)
    changeset.subscribers.push(user)

    assert_difference "changeset.subscribers.count", -1 do
      post :unsubscribe, :params => { :id => changeset.id }
    end
    assert_response :success

    # not closed changeset
    changeset = create(:changeset)
    changeset.subscribers.push(user)

    assert_difference "changeset.subscribers.count", -1 do
      post :unsubscribe, :params => { :id => changeset.id }
    end
    assert_response :success
  end

  ##
  # test unsubscribe fail
  def test_unsubscribe_fail
    # unauthorized
    changeset = create(:changeset, :closed)
    assert_no_difference "changeset.subscribers.count" do
      post :unsubscribe, :params => { :id => changeset.id }
    end
    assert_response :unauthorized

    basic_authorization create(:user).email, "test"

    # bad changeset id
    assert_no_difference "changeset.subscribers.count" do
      post :unsubscribe, :params => { :id => 999111 }
    end
    assert_response :not_found

    # trying to unsubscribe when not subscribed
    changeset = create(:changeset, :closed)
    assert_no_difference "changeset.subscribers.count" do
      post :unsubscribe, :params => { :id => changeset.id }
    end
    assert_response :not_found
  end

  private

  ##
  # boilerplate for checking that certain changesets exist in the
  # output.
  def assert_changesets(changesets)
    assert_select "osm>changeset", changesets.size
    changesets.each do |changeset|
      assert_select "osm>changeset[id='#{changeset.id}']", 1
    end
  end

  ##
  # call the include method and assert properties of the bbox
  def check_after_include(changeset_id, lon, lat, bbox)
    xml = "<osm><node lon='#{lon}' lat='#{lat}'/></osm>"
    post :expand_bbox, :params => { :id => changeset_id }, :body => xml
    assert_response :success, "Setting include of changeset failed: #{@response.body}"

    # check exactly one changeset
    assert_select "osm>changeset", 1
    assert_select "osm>changeset[id='#{changeset_id}']", 1

    # check the bbox
    doc = XML::Parser.string(@response.body).parse
    changeset = doc.find("//osm/changeset").first
    assert_equal bbox[0], changeset["min_lon"].to_f, "min lon"
    assert_equal bbox[1], changeset["min_lat"].to_f, "min lat"
    assert_equal bbox[2], changeset["max_lon"].to_f, "max lon"
    assert_equal bbox[3], changeset["max_lat"].to_f, "max lat"
  end

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

  ##
  # check the result of a index
  def check_index_result(changesets)
    changesets = changesets.where("num_changes > 0")
                           .order(:created_at => :desc)
                           .limit(20)
    assert changesets.size <= 20

    assert_select "ol.changesets", :count => [changesets.size, 1].min do
      assert_select "li", :count => changesets.size

      changesets.each do |changeset|
        assert_select "li#changeset_#{changeset.id}", :count => 1
      end
    end
  end

  ##
  # check the result of a feed
  def check_feed_result(changesets)
    assert changesets.size <= 20

    assert_select "feed", :count => [changesets.size, 1].min do
      assert_select "> title", :count => 1, :text => /^Changesets/
      assert_select "> entry", :count => changesets.size

      changesets.each do |changeset|
        assert_select "> entry > id", changeset_url(:id => changeset.id)
      end
    end
  end
end
