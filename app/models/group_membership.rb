class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :group_id

  ##
  # a simple role system; possible to expand in the future
  module Roles
    LEADER = "Leader"
    MEMBER = ""

    ALL_ROLES = [MEMBER, LEADER]
  end

  #attr_accessible :role

  def set_role(new_role)
    update_attribute(:role, new_role)
  end

  def has_role?(test_role)
    role == test_role
  end

  def is_a_leader?
    has_role? Roles::LEADER
  end
end
