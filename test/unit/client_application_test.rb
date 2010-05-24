require File.dirname(__FILE__) + '/../test_helper'

class ClientApplicationTest < ActiveSupport::TestCase
  api_fixtures

  ##
  # test that tokens can't be found unless they're authorised
  def test_find_token
    tok = client_applications(:oauth_web_app).create_request_token
    assert_equal false, tok.authorized?, "Token should be created unauthorised."
    assert_equal nil, ClientApplication.find_token(tok.token), "Shouldn't be able to find unauthorised token"
    tok.authorize!(users(:public_user))
    assert_equal true, tok.authorized?, "Token should now be authorised."
    assert_not_equal nil, ClientApplication.find_token(tok.token), "Should be able to find authorised token"
  end

end
