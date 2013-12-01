require File.dirname(__FILE__) + '/../test_helper'

class RedirectTest  < ActionDispatch::IntegrationTest
  def test_search_redirects
    get "/?query=test"
    assert_response :redirect
    assert_redirected_to "/search?query=test"
  end

  def test_history_redirects
    get "/browse"
    assert_response :redirect
    assert_redirected_to "/history"

    get "/browse/changesets"
    assert_response :redirect
    assert_redirected_to "/history"

    get "/browse/changesets?bbox=-80.54%2C40.358%2C-79.526%2C40.779"
    assert_response :redirect
    assert_redirected_to "/history?bbox=-80.54%2C40.358%2C-79.526%2C40.779"

    get "/browse/friends"
    assert_response :redirect
    assert_redirected_to "/history/friends"

    get "/browse/nearby"
    assert_response :redirect
    assert_redirected_to "/history/nearby"

    get "/user/name/edits"
    assert_response :redirect
    assert_redirected_to "/user/name/history"
  end

  def test_history_feed_redirects
    get "/browse/changesets/feed"
    assert_response :redirect
    assert_redirected_to "/history/feed"

    get "/browse/changesets/feed?bbox=-80.54%2C40.358%2C-79.526%2C40.779"
    assert_response :redirect
    assert_redirected_to "/history/feed?bbox=-80.54%2C40.358%2C-79.526%2C40.779"

    get "/user/name/edits/feed"
    assert_response :redirect
    assert_redirected_to "/user/name/history/feed"
  end

  def test_browse_redirects
    get "/browse/node/1"
    assert_response :redirect
    assert_redirected_to "/node/1"

    get "/browse/way/1"
    assert_response :redirect
    assert_redirected_to "/way/1"

    get "/browse/relation/1"
    assert_response :redirect
    assert_redirected_to "/relation/1"

    get "/browse/changeset/1"
    assert_response :redirect
    assert_redirected_to "/changeset/1"

    get "/browse/note/1"
    assert_response :redirect
    assert_redirected_to "/note/1"
  end

  def test_browse_history_redirects
    get "/browse/node/1/history"
    assert_response :redirect
    assert_redirected_to "/node/1/history"

    get "/browse/way/1/history"
    assert_response :redirect
    assert_redirected_to "/way/1/history"

    get "/browse/relation/1/history"
    assert_response :redirect
    assert_redirected_to "/relation/1/history"
  end
end
