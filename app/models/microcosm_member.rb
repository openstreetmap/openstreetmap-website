# == Schema Information
#
# Table name: microcosm_members
#
#  id           :bigint(8)        not null, primary key
#  microcosm_id :integer          not null
#  user_id      :integer          not null
#  role         :string(64)       not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_microcosm_members_on_microcosm_id                       (microcosm_id)
#  index_microcosm_members_on_microcosm_id_and_user_id_and_role  (microcosm_id,user_id,role) UNIQUE
#  index_microcosm_members_on_user_id                            (user_id)
#

class MicrocosmMember < ApplicationRecord
  belongs_to :microcosm
  belongs_to :user

  # TODO: validate uniqueness of user's role in each microcosm.

  module Roles
    ORGANIZER = "organizer".freeze
    MEMBER = "member".freeze
    ALL_ROLES = [ORGANIZER, MEMBER].freeze
  end
end
