require File.dirname(__FILE__) + '/../test_helper'
require 'old_way_controller'

class OldWayControllerTest < ActionController::TestCase
  api_fixtures

  # -------------------------------------
  # Test reading old ways.
  # -------------------------------------

  def test_history_visible
    # check that a visible way is returned properly
    get :history, :id => ways(:visible_way).way_id
    assert_response :success
  end
  
  def test_history_invisible
    # check that an invisible way's history is returned properly
    get :history, :id => ways(:invisible_way).way_id
    assert_response :success
  end
  
  def test_history_invalid
    # check chat a non-existent way is not returned
    get :history, :id => 0
    assert_response :not_found
  end
  
  ##
  # check that we can retrieve versions of a way
  def test_version
    check_current_version(current_ways(:visible_way).id)
    check_current_version(current_ways(:used_way).id)
    check_current_version(current_ways(:way_with_versions).id)
  end

  ##
  # check that returned history is the same as getting all 
  # versions of a way from the api.
  def test_history_equals_versions
    check_history_equals_versions(current_ways(:visible_way).id)
    check_history_equals_versions(current_ways(:used_way).id)
    check_history_equals_versions(current_ways(:way_with_versions).id)
  end

  ##
  # check that the current version of a way is equivalent to the
  # version which we're getting from the versions call.
  def check_current_version(way_id)
    # get the current version
    current_way = with_controller(WayController.new) do
      get :read, :id => way_id
      assert_response :success, "can't get current way #{way_id}"
      Way.from_xml(@response.body)
    end
    assert_not_nil current_way, "getting way #{way_id} returned nil"

    # get the "old" version of the way from the version method
    get :version, :id => way_id, :version => current_way.version
    assert_response :success, "can't get old way #{way_id}, v#{current_way.version}"
    old_way = Way.from_xml(@response.body)

    # check that the ways are identical
    assert_ways_are_equal current_way, old_way
  end

  ##
  # look at all the versions of the way in the history and get each version from
  # the versions call. check that they're the same.
  def check_history_equals_versions(way_id)
    get :history, :id => way_id
    assert_response :success, "can't get way #{way_id} from API"
    history_doc = XML::Parser.string(@response.body).parse
    assert_not_nil history_doc, "parsing way #{way_id} history failed"

    history_doc.find("//osm/way").each do |way_doc|
      history_way = Way.from_xml_node(way_doc)
      assert_not_nil history_way, "parsing way #{way_id} version failed"

      get :version, :id => way_id, :version => history_way.version
      assert_response :success, "couldn't get way #{way_id}, v#{history_way.version}"
      version_way = Way.from_xml(@response.body)
      assert_not_nil version_way, "failed to parse #{way_id}, v#{history_way.version}"
      
      assert_ways_are_equal history_way, version_way
    end
  end

end
