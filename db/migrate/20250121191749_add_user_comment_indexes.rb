class AddUserCommentIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :changeset_comments, [:author_id, :id], :algorithm => :concurrently
    add_index :diary_comments, [:user_id, :id], :algorithm => :concurrently
  end
end
