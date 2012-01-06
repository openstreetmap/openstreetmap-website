require 'migrate'

class CreateUserBlocks < ActiveRecord::Migration
  def self.up
    create_table :user_blocks do |t|
      t.column :user_id,      :bigint,   :null => false
      t.column :moderator_id, :bigint,   :null => false
      t.column :reason,       :text,     :null => false
      t.column :end_at,       :datetime, :null => false
      t.column :needs_view,   :boolean,  :null => false, :default => false
      t.column :revoker_id,   :bigint

      t.timestamps
    end

    add_foreign_key :user_blocks, [:user_id], :users, [:id]
    add_foreign_key :user_blocks, [:moderator_id], :users, [:id]
    add_foreign_key :user_blocks, [:revoker_id], :users, [:id]

    add_index :user_blocks, [:user_id]
  end

  def self.down
    drop_table :user_blocks
  end
end
