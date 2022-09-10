class AddAuthorIndexToNoteComments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :note_comments, [:author_id, :created_at], :algorithm => :concurrently
  end
end
