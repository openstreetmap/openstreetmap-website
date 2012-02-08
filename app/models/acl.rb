class Acl < ActiveRecord::Base
  def self.match(address, domain = nil)
    if domain
      condition = Acl.where("address >> ? OR domain = ?", address, domain)
    else
      condition = Acl.where("address >> ?", address)
    end
  end
end
