require File.dirname(__FILE__) + '/../test_helper'
require 'old_node_controller'

# Re-raise errors caught by the controller.
class OldNodeController; def rescue_action(e) raise e end; end

class OldNodeControllerTest < Test::Unit::TestCase
  api_fixtures

  def setup
    @controller = OldNodeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  #
  # TODO: test history
  #

  ##
  # test the version call by submitting several revisions of a new node
  # to the API and ensuring that later calls to version return the 
  # matching versions of the object.
  def test_version
    basic_authorization(users(:normal_user).email, "test")
    changeset_id = changesets(:normal_user_first_change).id

    # setup a simple XML node
    xml_doc = current_nodes(:visible_node).to_xml
    xml_node = xml_doc.find("//osm/node").first
    nodeid = current_nodes(:visible_node).id

    # keep a hash of the versions => string, as we'll need something
    # to test against later
    versions = Hash.new

    # save a version for later checking
    versions[xml_node['version']] = xml_doc.to_s

    # randomly move the node about
    20.times do 
      # move the node somewhere else
      xml_node['lat'] = precision(rand * 180 -  90).to_s
      xml_node['lon'] = precision(rand * 360 - 180).to_s
      with_controller(NodeController.new) do
        content xml_doc
        put :update, :id => nodeid
        assert_response :success
        xml_node['version'] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node['version']] = xml_doc.to_s
    end

    # add a bunch of random tags
    30.times do 
      xml_tag = XML::Node.new("tag")
      xml_tag['k'] = random_string
      xml_tag['v'] = random_string
      xml_node << xml_tag
      with_controller(NodeController.new) do
        content xml_doc
        put :update, :id => nodeid
        assert_response :success,
        "couldn't update node #{nodeid} (#{@response.body})"
        xml_node['version'] = @response.body.to_s
      end
      # save a version for later checking
      versions[xml_node['version']] = xml_doc.to_s
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

  ##
  # for some reason a==b is false, but there doesn't seem to be any 
  # difference between the nodes, so i'm checking all the attributes 
  # manually and blaming it on ActiveRecord
  def assert_nodes_are_equal(a, b)
    assert_equal a.id, b.id, "node IDs"
    assert_equal a.latitude, b.latitude, "latitude"
    assert_equal a.longitude, b.longitude, "longitude"
    assert_equal a.changeset_id, b.changeset_id, "changeset ID"
    assert_equal a.visible, b.visible, "visible"
    assert_equal a.version, b.version, "version"
    assert_equal a.tags, b.tags, "tags"
  end

  ##
  # returns a 16 character long string with some nasty characters in it.
  # this ought to stress-test the tag handling as well as the versioning.
  def random_string
    letters = [['!','"','$','&',';','@'],
               ('a'..'z').to_a,
               ('A'..'Z').to_a,
               ('0'..'9').to_a].flatten
    (1..16).map { |i| letters[ rand(letters.length) ] }.join
  end

  ##
  # truncate a floating point number to the scale that it is stored in
  # the database. otherwise rounding errors can produce failing unit
  # tests when they shouldn't.
  def precision(f)
    return (f * GeoRecord::SCALE).round.to_f / GeoRecord::SCALE
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end

  ##
  # takes a block which is executed in the context of a different 
  # ActionController instance. this is used so that code can call methods
  # on the node controller whilst testing the old_node controller.
  def with_controller(new_controller)
    controller_save = @controller
    begin
      @controller = new_controller
      yield
    ensure
      @controller = controller_save
    end
  end

end
