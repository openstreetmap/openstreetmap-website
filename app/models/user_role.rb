# == Schema Information
#
# Table name: user_roles
#
#  id         :integer          not null, primary key
#  user_id    :bigint(8)        not null
#  role       :enum             not null
#  created_at :datetime
#  updated_at :datetime
#  granter_id :bigint(8)        not null
#
# Indexes
#
#  user_roles_id_role_unique  (user_id,role) UNIQUE
#
# Foreign Keys
#
#  user_roles_granter_id_fkey  (granter_id => users.id)
#  user_roles_user_id_fkey     (user_id => users.id)
#

class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :granter, :class_name => "User"

  ALL_ROLES = %w[administrator moderator].freeze

  validates :role, :inclusion => ALL_ROLES, :uniqueness => { :scope => :user_id }
end
