# frozen_string_literal: true

require "test_helper"

class InetValidatorTest < ActiveSupport::TestCase
  def test_valid_addresses
    ["192.0.2.7", "192.0.2.0/24", "2001:db8::1", "2001:db8::/32"].each do |address|
      acl = Acl.new(:k => "test", :address => address)
      assert_predicate acl, :valid?, "'#{address}' should be valid"
    end
  end

  def test_blank_addresses
    [nil, ""].each do |address|
      acl = Acl.new(:k => "test", :address => address)
      assert_predicate acl, :valid?, "#{address.inspect} should be valid"
      assert_nil acl.address
    end
  end

  def test_invalid_addresses
    ["not-an-address", "192.0.2", "192.0.2.256", "192.0.2.0/33"].each do |address|
      acl = Acl.new(:k => "test", :address => address)
      assert_not_predicate acl, :valid?, "'#{address}' should not be valid"
      assert_includes acl.errors[:address], "is invalid"
    end
  end
end
