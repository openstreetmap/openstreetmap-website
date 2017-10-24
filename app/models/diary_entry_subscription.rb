# == Schema Information
#
# Table name: diary_entry_subscriptions
#
#  user_id        :integer          not null, primary key
#  diary_entry_id :integer          not null, primary key
#
# Indexes
#
#  index_diary_entry_subscriptions_on_diary_entry_id  (diary_entry_id)
#
# Foreign Keys
#
#  diary_entry_subscriptions_diary_entry_id_fkey  (diary_entry_id => diary_entries.id)
#  diary_entry_subscriptions_user_id_fkey         (user_id => users.id)
#

class DiaryEntrySubscription < ActiveRecord::Base
  self.primary_keys = "user_id", "diary_entry_id"

  belongs_to :user
  belongs_to :diary_entry
end
