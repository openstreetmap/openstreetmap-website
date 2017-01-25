require "test_helper"

class OauthNonceTest < ActiveSupport::TestCase
  api_fixtures

  ##
  # the nonce has only one property, that it is a unique pair of
  # string and timestamp.
  def test_nonce_uniqueness
    string = "0123456789ABCDEF"
    timestamp = Time.now.to_i

    nonce1 = OauthNonce.remember(string, timestamp)
    assert_not_equal false, nonce1, "First nonce should be unique. Check your test database is empty."

    nonce2 = OauthNonce.remember(string, timestamp)
    assert_equal false, nonce2, "Shouldn't be able to remember the same nonce twice."
  end

  ##
  # nonces that are not current should be rejected
  def test_nonce_not_current
    string = "0123456789ABCDEF"

    nonce1 = OauthNonce.remember(string, Time.now.to_i - 86430)
    assert_equal false, nonce1, "Nonces over a day in the past should be rejected"

    nonce2 = OauthNonce.remember(string, Time.now.to_i - 86370)
    assert_not_equal false, nonce2, "Nonces under a day in the past should be rejected"
  end
end
