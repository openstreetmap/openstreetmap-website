require "test_helper"
require "old_way_controller"

class OldWayControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/way/1/history", :method => :get },
      { :controller => "old_way", :action => "history", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/way/1/2", :method => :get },
      { :controller => "old_way", :action => "version", :id => "1", :version => "2" }
    )
    assert_routing(
      { :path => "/api/0.6/way/1/2/redact", :method => :post },
      { :controller => "old_way", :action => "redact", :id => "1", :version => "2" }
    )
  end

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
    create(:way_tag, :way => current_ways(:visible_way))
    create(:way_tag, :way => current_ways(:used_way))
    create(:way_tag, :way => current_ways(:way_with_versions))
    propagate_tags(current_ways(:visible_way), ways(:visible_way))
    propagate_tags(current_ways(:used_way), ways(:used_way))
    propagate_tags(current_ways(:way_with_versions), ways(:way_with_versions_v4))

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
  # test the redaction of an old version of a way, while not being
  # authorised.
  def test_redact_way_unauthorised
    do_redact_way(ways(:way_with_versions_v3),
                  create(:redaction))
    assert_response :unauthorized, "should need to be authenticated to redact."
  end

  ##
  # test the redaction of an old version of a way, while being
  # authorised as a normal user.
  def test_redact_way_normal_user
    user = create(:user)
    basic_authorization(user.email, "test")

    do_redact_way(ways(:way_with_versions_v3),
                  create(:redaction, :user => user))
    assert_response :forbidden, "should need to be moderator to redact."
  end

  ##
  # test that, even as moderator, the current version of a way
  # can't be redacted.
  def test_redact_way_current_version
    moderator_user = create(:moderator_user)
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_way(ways(:way_with_versions_v4),
                  create(:redaction, :user => moderator_user))
    assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
  end

  ##
  # test that redacted ways aren't visible, regardless of
  # authorisation except as moderator...
  def test_version_redacted
    way = ways(:way_with_redacted_versions_v2)

    get :version, :id => way.way_id, :version => way.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API."

    # not even to a logged-in user
    basic_authorization(create(:user).email, "test")
    get :version, :id => way.way_id, :version => way.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API, even when logged in."
  end

  ##
  # test that redacted nodes aren't visible in the history
  def test_history_redacted
    way = ways(:way_with_redacted_versions_v2)

    get :history, :id => way.way_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 0, "redacted way #{way.way_id} version #{way.version} shouldn't be present in the history."

    # not even to a logged-in user
    basic_authorization(create(:user).email, "test")
    get :version, :id => way.way_id, :version => way.version
    get :history, :id => way.way_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 0, "redacted node #{way.way_id} version #{way.version} shouldn't be present in the history, even when logged in."
  end

  ##
  # test the redaction of an old version of a way, while being
  # authorised as a moderator.
  def test_redact_way_moderator
    moderator_user = create(:moderator_user)
    way = ways(:way_with_versions_v3)
    basic_authorization(moderator_user.email, "test")

    do_redact_way(way, create(:redaction, :user => moderator_user))
    assert_response :success, "should be OK to redact old version as moderator."

    # check moderator can still see the redacted data, when passing
    # the appropriate flag
    get :version, :id => way.way_id, :version => way.version
    assert_response :forbidden, "After redaction, node should be gone for moderator, when flag not passed."
    get :version, :id => way.way_id, :version => way.version, :show_redactions => "true"
    assert_response :success, "After redaction, node should not be gone for moderator, when flag passed."

    # and when accessed via history
    get :history, :id => way.way_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 0, "way #{way.way_id} version #{way.version} should not be present in the history for moderators when not passing flag."
    get :history, :id => way.way_id, :show_redactions => "true"
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 1, "way #{way.way_id} version #{way.version} should still be present in the history for moderators when passing flag."
  end

  # testing that if the moderator drops auth, he can't see the
  # redacted stuff any more.
  def test_redact_way_is_redacted
    moderator_user = create(:moderator_user)
    way = ways(:way_with_versions_v3)
    basic_authorization(moderator_user.email, "test")

    do_redact_way(way, create(:redaction, :user => moderator_user))
    assert_response :success, "should be OK to redact old version as moderator."

    # re-auth as non-moderator
    basic_authorization(create(:user).email, "test")

    # check can't see the redacted data
    get :version, :id => way.way_id, :version => way.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API."

    # and when accessed via history
    get :history, :id => way.way_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 0, "redacted way #{way.way_id} version #{way.version} shouldn't be present in the history."
  end

  ##
  # test the unredaction of an old version of a way, while not being
  # authorised.
  def test_unredact_way_unauthorised
    way = ways(:way_with_redacted_versions_v3)

    post :redact, :id => way.way_id, :version => way.version
    assert_response :unauthorized, "should need to be authenticated to unredact."
  end

  ##
  # test the unredaction of an old version of a way, while being
  # authorised as a normal user.
  def test_unredact_way_normal_user
    way = ways(:way_with_redacted_versions_v3)
    basic_authorization(create(:user).email, "test")

    post :redact, :id => way.way_id, :version => way.version
    assert_response :forbidden, "should need to be moderator to unredact."
  end

  ##
  # test the unredaction of an old version of a way, while being
  # authorised as a moderator.
  def test_unredact_way_moderator
    moderator_user = create(:moderator_user)
    way = ways(:way_with_redacted_versions_v3)
    basic_authorization(moderator_user.email, "test")

    post :redact, :id => way.way_id, :version => way.version
    assert_response :success, "should be OK to unredact old version as moderator."

    # check moderator can still see the redacted data, without passing
    # the appropriate flag
    get :version, :id => way.way_id, :version => way.version
    assert_response :success, "After redaction, node should not be gone for moderator, when flag passed."

    # and when accessed via history
    get :history, :id => way.way_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 1, "way #{way.way_id} version #{way.version} should still be present in the history for moderators when passing flag."

    basic_authorization(users(:normal_user).email, "test")

    # check normal user can now see the redacted data
    get :version, :id => way.way_id, :version => way.version
    assert_response :success, "After redaction, node should not be gone for moderator, when flag passed."

    # and when accessed via history
    get :history, :id => way.way_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm way[id='#{way.way_id}'][version='#{way.version}']", 1, "way #{way.way_id} version #{way.version} should still be present in the history for moderators when passing flag."
  end

  private

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

  def do_redact_way(way, redaction)
    get :version, :id => way.way_id, :version => way.version
    assert_response :success, "should be able to get version #{way.version} of way #{way.way_id}."

    # now redact it
    post :redact, :id => way.way_id, :version => way.version, :redaction => redaction.id
  end

  def propagate_tags(way, old_way)
    way.tags.each do |k, v|
      create(:old_way_tag, :old_way => old_way, :k => k, :v => v)
    end
  end
end
