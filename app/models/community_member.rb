# == Schema Information
#
# Table name: community_members
#
#  id           :bigint(8)        not null, primary key
#  community_id :integer          not null
#  user_id      :integer          not null
#  role         :string(64)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_community_members_on_community_id                       (community_id)
#  index_community_members_on_community_id_and_user_id_and_role  (community_id,user_id,role) UNIQUE
#  index_community_members_on_user_id                            (user_id)
#

class CommunityMember < ApplicationRecord
  belongs_to :community
  belongs_to :user

  # TODO: validate uniqueness of user's role in each community.

  module Roles
    ORGANIZER = "organizer".freeze
    MEMBER = "member".freeze
    ALL_ROLES = [ORGANIZER, MEMBER].freeze
  end
end
