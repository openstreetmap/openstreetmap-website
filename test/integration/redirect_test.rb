require "test_helper"

class RedirectTest < ActionDispatch::IntegrationTest
  def test_legacy_redirects
    get "/index.html"
    assert_redirected_to "/"

    get "/create-account.html"
    assert_redirected_to "/user/new"

    get "/forgot-password.html"
    assert_redirected_to "/user/forgot-password"
  end

  def test_search_redirects
    get "/?query=test"
    assert_redirected_to "/search?query=test"
  end
end
