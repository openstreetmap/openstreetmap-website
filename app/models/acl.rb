class Acl < ActiveRecord::Base
  scope :address, lambda { |address| where("? & netmask = address", address) }
end
