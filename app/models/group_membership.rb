class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :group_id

  attr_accessible :role # TODO: turn this into a pseudo-enumerable
end
