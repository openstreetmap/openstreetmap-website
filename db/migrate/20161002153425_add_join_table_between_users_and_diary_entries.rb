class AddJoinTableBetweenUsersAndDiaryEntries < ActiveRecord::Migration
  def change
    create_table :diary_entry_subscriptions, :id => false do |t|
      t.column :user_id, :bigint, :null => false
      t.column :diary_entry_id, :bigint, :null => false
    end

    add_index :diary_entry_subscriptions, [:user_id, :diary_entry_id], :unique => true, :name => "index_diary_subscriptions_on_user_id_and_diary_entry_id"
    add_index :diary_entry_subscriptions, [:diary_entry_id]
  end
end
