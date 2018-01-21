require "migrate"

class AddJoinTableBetweenUsersAndDiaryEntries < ActiveRecord::Migration[5.0]
  def self.up
    create_table :diary_entry_subscriptions, :id => false do |t|
      t.column :user_id, :bigint, :null => false
      t.column :diary_entry_id, :bigint, :null => false
    end

    add_primary_key :diary_entry_subscriptions, [:user_id, :diary_entry_id]
    add_index :diary_entry_subscriptions, [:diary_entry_id]
    add_foreign_key :diary_entry_subscriptions, :diary_entries, :name => "diary_entry_subscriptions_diary_entry_id_fkey"
    add_foreign_key :diary_entry_subscriptions, :users, :name => "diary_entry_subscriptions_user_id_fkey"
  end

  def self.down
    drop_table :diary_entry_subscriptions
  end
end
