class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, :class_name => "User"

  ALL_ROLES = %w[administrator moderator].freeze

  validates :role, :inclusion => ALL_ROLES, :uniqueness => { :scope => :user_id }
end
