require "test_helper"

class OauthTokenTest < ActiveSupport::TestCase
  ##
  # check that after calling invalidate! on a token, it is invalid.
  def test_token_invalidation
    tok = OauthToken.new
    assert_not tok.invalidated?, "Token should be created valid."
    tok.invalidate!
    assert tok.invalidated?, "Token should now be invalid."
  end

  ##
  # check that an authorized token is authorised and can be invalidated
  def test_token_authorisation
    tok = RequestToken.create(:client_application => create(:client_application))
    assert_not tok.authorized?, "Token should be created unauthorised."
    tok.authorize!(create(:user))
    assert tok.authorized?, "Token should now be authorised."
    tok.invalidate!
    assert_not tok.authorized?, "Token should now be invalid."
  end
end
