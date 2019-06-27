require "migrate"

class CreateUserBlocks < ActiveRecord::Migration[4.2]
  def change
    create_table :user_blocks do |t|
      t.column :user_id,      :bigint,   :null => false
      t.column :moderator_id, :bigint,   :null => false
      t.column :reason,       :text,     :null => false
      t.column :end_at,       :datetime, :null => false
      t.column :needs_view,   :boolean,  :null => false, :default => false
      t.column :revoker_id,   :bigint

      t.timestamps :null => true
    end

    add_foreign_key :user_blocks, :users, :name => "user_blocks_user_id_fkey"
    add_foreign_key :user_blocks, :users, :column => :moderator_id, :name => "user_blocks_moderator_id_fkey"
    add_foreign_key :user_blocks, :users, :column => :revoker_id, :name => "user_blocks_revoker_id_fkey"

    add_index :user_blocks, [:user_id]
  end
end
