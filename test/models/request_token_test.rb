require "test_helper"

class RequestTokenTest < ActiveSupport::TestCase
  def test_oob
    assert RequestToken.new.oob?
    assert RequestToken.new(:callback_url => "oob").oob?
    assert RequestToken.new(:callback_url => "OOB").oob?
    assert_not RequestToken.new(:callback_url => "http://test.host/").oob?
  end
end
