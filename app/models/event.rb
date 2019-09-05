# == Schema Information
#
# Table name: events
#
#  id           :bigint(8)        not null, primary key
#  title        :string
#  moment       :datetime
#  location     :string
#  description  :text
#  microcosm_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Event < ApplicationRecord
  belongs_to :microcosm
  has_many :event_attendances

  def attendees
    EventAttendance.where(event_id: id, intention: "Yes")
  end
end
