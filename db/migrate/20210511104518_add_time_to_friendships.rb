class AddTimeToFriendships < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_column :friends, :created_at, :datetime
    add_index :friends, [:user_id, :created_at], :algorithm => :concurrently
    remove_index :friends, :column => :user_id, :name => "friends_user_id_idx"
  end
end
