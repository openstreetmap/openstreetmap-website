class AddJoinTableBetweenUsersAndDiaryEntries < ActiveRecord::Migration
  def change
    create_table :diary_entries_subscribers, :id => false do |t|
      t.column :subscriber_id, :bigint, :null => false
      t.column :diary_entry_id, :bigint, :null => false
    end

    add_foreign_key :diary_entries_subscribers, :users, :column => :subscriber_id, :name => "diary_entries_subscribers_subscriber_id_fkey"
    add_foreign_key :diary_entries_subscribers, :diary_entries, :column => :diary_entry_id, :name => "diary_entries_subscribers_changeset_id_fkey"

    add_index :diary_entries_subscribers, [:subscriber_id, :diary_entry_id], :unique => true, :name => "index_diary_subscribers_on_subscriber_id_and_diary_id"
    add_index :diary_entries_subscribers, [:diary_entry_id]
  end

  def up
    DiaryEntry.find_each do |diary_entry|
      diary_entry.subscribers << diary_entry.user unless diary_entry.subscribers.exists?(diary_entry.user.id)
    end
  end

  def down
  end
end
