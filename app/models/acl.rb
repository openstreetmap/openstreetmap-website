class Acl < ActiveRecord::Base
  scope :address, lambda { |address| where("#{inet_aton} & netmask = address", address) }

private

  def self.inet_aton
    if self.connection.adapter_name == "MySQL"
      "inet_aton(?)"
    else
      "?"
    end
  end
end
