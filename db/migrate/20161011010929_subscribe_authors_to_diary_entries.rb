class SubscribeAuthorsToDiaryEntries < ActiveRecord::Migration[4.2]
  def up
    DiaryEntry.find_each do |diary_entry|
      diary_entry.subscriptions.create(:user => diary_entry.user) unless diary_entry.subscribers.exists?(diary_entry.user.id)
    end
  end

  def down; end
end
