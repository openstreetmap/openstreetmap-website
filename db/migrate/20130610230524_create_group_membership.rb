class CreateGroupMembership < ActiveRecord::Migration
  def up
    create_table :group_memberships do |t|
      t.integer :group_id
      t.integer :user_id
      t.string  :role
      t.timestamps
    end
    add_index :group_memberships, :group_id
    add_index :group_memberships, :user_id
    add_index :group_memberships, [:group_id, :user_id], :unique => true
  end

  def down
    drop_table :group_memberships
  end
end
