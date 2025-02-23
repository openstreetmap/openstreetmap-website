# == Schema Information
#
# Table name: user_mutes
#
#  id         :bigint           not null, primary key
#  owner_id   :bigint           not null
#  subject_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_mutes_on_owner_id_and_subject_id  (owner_id,subject_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#  fk_rails_...  (subject_id => users.id)
#
class UserMute < ApplicationRecord
  belongs_to :owner, :class_name => "User"
  belongs_to :subject, :class_name => "User"

  validates :subject, :uniqueness => { :scope => :owner_id, :message => :is_already_muted }

  def self.active?(owner:, subject:)
    !subject.administrator? &&
      !subject.moderator? &&
      exists?(
        :owner => owner,
        :subject => subject
      )
  end
end
