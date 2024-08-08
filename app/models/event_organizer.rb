# == Schema Information
#
# Table name: event_organizers
#
#  id         :bigint(8)        not null, primary key
#  event_id   :bigint(8)        not null
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_event_organizers_on_event_id  (event_id)
#  index_event_organizers_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#
class EventOrganizer < ApplicationRecord
  belongs_to :event
  belongs_to :user
end
