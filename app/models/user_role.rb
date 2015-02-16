class UserRole < ActiveRecord::Base
  belongs_to :user

  ALL_ROLES = %w(administrator moderator)

  validates_inclusion_of :role, :in => ALL_ROLES
  validates_uniqueness_of :role, :scope => :user_id
end
