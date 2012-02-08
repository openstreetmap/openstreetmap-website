class Acl < ActiveRecord::Base
  scope :address, lambda { |address| where("address >> ?", address) }
end
