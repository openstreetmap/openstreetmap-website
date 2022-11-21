require "test_helper"

class AclTest < ActiveSupport::TestCase
  def test_k_required
    acl = create(:acl)
    assert_predicate acl, :valid?
    acl.k = nil
    assert_not acl.valid?
  end

  def test_no_account_creation_by_subnet
    assert_not Acl.no_account_creation("192.168.1.1")
    create(:acl, :address => "192.168.0.0/16", :k => "no_account_creation")
    assert Acl.no_account_creation("192.168.1.1")
  end

  def test_no_account_creation_by_domain
    assert_not Acl.no_account_creation("192.168.1.1", :domain => "example.com")
    assert_not Acl.no_account_creation("192.168.1.1", :domain => "test.example.com")
    create(:acl, :domain => "example.com", :k => "no_account_creation")
    assert Acl.no_account_creation("192.168.1.1", :domain => "example.com")
    assert Acl.no_account_creation("192.168.1.1", :domain => "test.example.com")
  end

  def test_no_account_creation_by_mx
    assert_not Acl.no_account_creation("192.168.1.1", :mx => "mail.example.com")
    create(:acl, :mx => "mail.example.com", :k => "no_account_creation")
    assert Acl.no_account_creation("192.168.1.1", :mx => "mail.example.com")
  end
end
