# frozen_string_literal: true

require "test_helper"

class AclsHelperTest < ActionView::TestCase
  def test_acl_address
    assert_nil acl_address(nil)
    assert_equal "192.0.2.7", acl_address(IPAddr.new("192.0.2.7"))
    assert_equal "192.0.2.0/24", acl_address(IPAddr.new("192.0.2.0/24"))
    assert_equal "2001:db8::1", acl_address(IPAddr.new("2001:db8::1"))
    assert_equal "2001:db8::/32", acl_address(IPAddr.new("2001:db8::/32"))
  end
end
