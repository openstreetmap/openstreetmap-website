# == Schema Information
#
# Table name: note_subscriptions
#
#  user_id :bigint           not null, primary key
#  note_id :bigint           not null, primary key
#
# Indexes
#
#  index_note_subscriptions_on_note_id  (note_id)
#
# Foreign Keys
#
#  fk_rails_...  (note_id => notes.id)
#  fk_rails_...  (user_id => users.id)
#
class NoteSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :note
end
