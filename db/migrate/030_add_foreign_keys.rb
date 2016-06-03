require "migrate"

class AddForeignKeys < ActiveRecord::Migration
  def self.up
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

    add_foreign_key :changeset_tags, :changesets, :column => :changeset_id, :name => "changeset_tags_id_fkey"
    add_foreign_key :diary_comments, :diary_entries, :name => "diary_comments_diary_entry_id_fkey"
    add_foreign_key :gps_points, :gpx_files, :column => :gpx_id, :name => "gps_points_gpx_id_fkey"
    add_foreign_key :gpx_file_tags, :gpx_files, :column => :gpx_id, :name => "gpx_file_tags_gpx_id_fkey"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
