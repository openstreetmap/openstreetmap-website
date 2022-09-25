# == Schema Information
#
# Table name: community_members
#
#  id           :bigint(8)        not null, primary key
#  community_id :bigint(8)        not null
#  user_id      :bigint(8)        not null
#  role         :enum             default("member"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_community_members_on_community_id                       (community_id)
#  index_community_members_on_community_id_and_user_id_and_role  (community_id,user_id,role) UNIQUE
#  index_community_members_on_user_id                            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (community_id => communities.id)
#  fk_rails_...  (user_id => users.id)
#

class CommunityMember < ApplicationRecord
  module Roles
    ORGANIZER = "organizer".freeze
    MEMBER = "member".freeze
    ALL_ROLES = [ORGANIZER, MEMBER].freeze
  end

  belongs_to :community
  belongs_to :user

  scope :organizers, -> { where(:role => Roles::ORGANIZER) }
  scope :members, -> { where(:role => Roles::MEMBER) }

  validates :community, :associated => true
  validates :user, :associated => true
  validates :role, :inclusion => { :in => Roles::ALL_ROLES }

  # TODO: validate uniqueness of user's role in each community.

  # We assume this user already belongs to this community.
  def can_be_deleted
    issues = []
    # The user may also be an organizer under a separate membership.
    issues.append(:is_organizer) if CommunityMember.exists?(:community_id => community_id, :user_id => user_id, :role => Roles::ORGANIZER)

    issues
  end
end
