# == Schema Information
#
# Table name: event_attendances
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  event_id   :bigint(8)        not null
#  intention  :enum             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_event_attendances_on_event_id              (event_id)
#  index_event_attendances_on_user_id               (user_id)
#  index_event_attendances_on_user_id_and_event_id  (user_id,event_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#

class EventAttendance < ApplicationRecord
  module Intentions
    YES = "Yes".freeze
    NO = "No".freeze
    MAYBE = "Maybe".freeze
    ALL_INTENTIONS = [YES, NO, MAYBE].freeze
  end
  validates :intention, :inclusion => { :in => Intentions::ALL_INTENTIONS }

  belongs_to :event
  belongs_to :user
end
