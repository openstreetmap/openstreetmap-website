# == Schema Information
#
# Table name: user_mutes
#
#  id           :bigint(8)        not null, primary key
#  creator_id   :bigint(8)        not null
#  appointee_id :bigint(8)        not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_user_mutes_on_appointee_id                 (appointee_id)
#  index_user_mutes_on_creator_id                   (creator_id)
#  index_user_mutes_on_creator_id_and_appointee_id  (creator_id,appointee_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (appointee_id => users.id)
#  fk_rails_...  (creator_id => users.id)
#
class UserMute < ApplicationRecord
  belongs_to :creator, :class_name => "User"
  belongs_to :appointee, :class_name => "User"

  validates :appointee, :uniqueness => { :scope => :creator_id }

  def self.for_message?(message)
    active_for?(
      current_user: message.recipient,
      other_user: message.sender,
    )
  end

  def self.active_for?(current_user:, other_user:)
    exists?(
      creator: current_user,
      appointee: other_user
    )
  end
end
