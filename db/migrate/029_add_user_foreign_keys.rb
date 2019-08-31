require "migrate"

class AddUserForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :changesets, :users, :name => "changesets_user_id_fkey"
    add_foreign_key :diary_comments, :users, :name => "diary_comments_user_id_fkey"
    add_foreign_key :diary_entries, :users, :name => "diary_entries_user_id_fkey"
    add_foreign_key :friends, :users, :name => "friends_user_id_fkey"
    add_foreign_key :friends, :users, :column => :friend_user_id, :name => "friends_friend_user_id_fkey"
    add_foreign_key :gpx_files, :users, :name => "gpx_files_user_id_fkey"
    add_foreign_key :messages, :users, :column => :from_user_id, :name => "messages_from_user_id_fkey"
    add_foreign_key :messages, :users, :column => :to_user_id, :name => "messages_to_user_id_fkey"
    add_foreign_key :user_preferences, :users, :name => "user_preferences_user_id_fkey"
    add_foreign_key :user_tokens, :users, :name => "user_tokens_user_id_fkey"
  end
end
