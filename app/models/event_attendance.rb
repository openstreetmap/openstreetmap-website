# == Schema Information
#
# Table name: event_attendances
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  event_id   :integer          not null
#  intention  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_event_attendances_on_event_id  (event_id)
#  index_event_attendances_on_user_id   (user_id)
#

class EventAttendance < ApplicationRecord
  module Intentions
    YES = "yes".freeze
    NO = "no".freeze
    # MAYBE = "maybe".freeze  # This would be nice.
    ALL_INTENTIONS = [YES, NO].freeze
  end
  validates :intention, :inclusion => { :in => Intentions::ALL_INTENTIONS }

  belongs_to :event
  belongs_to :user
end
