require "test_helper"

class OauthTokenTest < ActiveSupport::TestCase
  ##
  # check that after calling invalidate! on a token, it is invalid.
  def test_token_invalidation
    tok = OauthToken.new
    assert_equal false, tok.invalidated?, "Token should be created valid."
    tok.invalidate!
    assert_equal true, tok.invalidated?, "Token should now be invalid."
  end

  ##
  # check that an authorized token is authorised and can be invalidated
  def test_token_authorisation
    tok = RequestToken.create(:client_application => create(:client_application))
    assert_equal false, tok.authorized?, "Token should be created unauthorised."
    tok.authorize!(create(:user))
    assert_equal true, tok.authorized?, "Token should now be authorised."
    tok.invalidate!
    assert_equal false, tok.authorized?, "Token should now be invalid."
  end
end
