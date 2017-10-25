class AddDiaryEntryCounterCaches < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :diary_entries_count, :integer, :null => false, :default => 0

    DiaryEntry.group(:user_id).pluck(:user_id).each do |user_id|
      User.reset_counters(user_id, :diary_entries)
    end
  end

  def self.down
    remove_column :users, :diary_entries_count
  end
end
