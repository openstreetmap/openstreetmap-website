class Acl < ActiveRecord::Base
  def self.find_by_address(address, options)
    self.with_scope(:find => {:conditions => ["#{inet_aton} & netmask = address", address]}) do
      return self.find(:first, options)
    end
  end

  def self.find_all_by_address(address, options)
    self.with_scope(:find => {:conditions => ["#{inet_aton} & netmask = address", address]}) do
      return self.find(:all, options)
    end
  end

private

  def self.inet_aton
    if self.connection.adapter_name == "MySQL"
      "inet_aton(?)"
    else
      "?"
    end
  end
end
