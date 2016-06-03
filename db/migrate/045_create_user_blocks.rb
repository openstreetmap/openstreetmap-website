require "migrate"

class CreateUserBlocks < ActiveRecord::Migration
  def change
    create_enumeration :format_enum, %w(html markdown text)

    create_table :user_blocks do |t|
      t.column :user_id,      :bigint,   :null => false
      t.column :creator_id, :bigint,   :null => false
      t.column :reason,       :text,     :null => false
      t.column :ends_at,       :datetime, :null => false
      t.column :needs_view,   :boolean,  :null => false, :default => false
      t.column :revoker_id,   :bigint
      t.column :reason_format, :format_enum, :null => false, :default => "markdown"

      t.timestamps :null => true
    end

    add_foreign_key :user_blocks, :users, :name => "user_blocks_user_id_fkey"
    add_foreign_key :user_blocks, :users, :column => :creator_id, :name => "user_blocks_creator_id_fkey"
    add_foreign_key :user_blocks, :users, :column => :revoker_id, :name => "user_blocks_revoker_id_fkey"

    add_index :user_blocks, [:user_id]


 
  end
end
