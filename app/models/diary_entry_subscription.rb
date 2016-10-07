class DiaryEntrySubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :diary_entry
end
