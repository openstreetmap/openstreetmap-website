require "test_helper"

class AclTest < ActiveSupport::TestCase
  def test_k_required
    acl = create(:acl)
    assert acl.valid?
    acl.k = nil
    assert !acl.valid?
  end

  def test_no_account_creation_by_subnet
    assert !Acl.no_account_creation("192.168.1.1")
    create(:acl, :address => "192.168.0.0/16", :k => "no_account_creation")
    assert Acl.no_account_creation("192.168.1.1")
  end

  def test_no_account_creation_by_domain
    assert !Acl.no_account_creation("192.168.1.1", "example.com")
    create(:acl, :domain => "example.com", :k => "no_account_creation")
    assert Acl.no_account_creation("192.168.1.1", "example.com")
  end
end
