require 'migrate'

class AddUserForeignKeys < ActiveRecord::Migration
  def self.up
    add_foreign_key :changesets, [:user_id], :users, [:id]
    add_foreign_key :diary_comments, [:user_id], :users, [:id]
    add_foreign_key :diary_entries, [:user_id], :users, [:id]
    add_foreign_key :friends, [:user_id], :users, [:id]
    add_foreign_key :friends, [:friend_user_id], :users, [:id]
    add_foreign_key :gpx_files, [:user_id], :users, [:id]
    add_foreign_key :messages, [:from_user_id], :users, [:id]
    add_foreign_key :messages, [:to_user_id], :users, [:id]
    add_foreign_key :user_preferences, [:user_id], :users, [:id]
    add_foreign_key :user_tokens, [:user_id], :users, [:id]
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
