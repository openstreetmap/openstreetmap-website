require File.dirname(__FILE__) + '/../test_helper'

class RedirectTest  < ActionDispatch::IntegrationTest
  def test_history_redirects
    get "/browse"
    assert_response :redirect
    assert_redirected_to "/history"

    get "/browse/changesets"
    assert_response :redirect
    assert_redirected_to "/history"
  end

  def test_history_feed_redirects
    get "/browse/changesets/feed"
    assert_response :redirect
    assert_redirected_to "/history/feed"
  end
end
