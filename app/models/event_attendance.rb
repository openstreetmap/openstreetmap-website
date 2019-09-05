# == Schema Information
#
# Table name: event_attendances
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer
#  event_id   :integer
#  intention  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class EventAttendance < ApplicationRecord
  belongs_to :event
end
