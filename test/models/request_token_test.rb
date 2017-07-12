require "test_helper"

class RequestTokenTest < ActiveSupport::TestCase
  def test_oob
    assert_equal true, RequestToken.new.oob?
    assert_equal true, RequestToken.new(:callback_url => "oob").oob?
    assert_equal true, RequestToken.new(:callback_url => "OOB").oob?
    assert_equal false, RequestToken.new(:callback_url => "http://test.host/").oob?
  end
end
