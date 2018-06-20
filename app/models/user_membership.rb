# == Schema Information
#
# Table name: user_roles
#
#  id         :integer          not null, primary key
#  user_id    :bigint(8)        not null
#  membership :enum             not null
#  show       :boolean
#
# Foreign Keys
#
#  user_memberships_user_id_fkey     (user_id => users.id)
#

class UserMembership < ActiveRecord::Base
  belongs_to :user

  ALL_MEMBERSHIPS = %w[OSMF].freeze

  validates :membership, :inclusion => ALL_MEMBERSHIPS, :uniqueness => { :scope => :user_id }
end
