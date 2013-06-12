class GroupMembership < ActiveRecord::Base
  module Roles
    LEADER = "Leader"
  end

  belongs_to :group
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :group_id

  attr_accessible :role
end
