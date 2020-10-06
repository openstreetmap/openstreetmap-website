class AddAuthorIndexToChangesetComments < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :changeset_comments, [:author_id, :created_at], :algorithm => :concurrently
  end
end
