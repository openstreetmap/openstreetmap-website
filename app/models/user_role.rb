class UserRole < ActiveRecord::Base
  belongs_to :user

  ALL_ROLES = %w(administrator moderator)

  validates :role, :inclusion => ALL_ROLES, :uniqueness => { :scope => :user_id }
end
