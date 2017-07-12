class DiaryEntrySubscription < ActiveRecord::Base
  self.primary_keys = "user_id", "diary_entry_id"

  belongs_to :user
  belongs_to :diary_entry
end
