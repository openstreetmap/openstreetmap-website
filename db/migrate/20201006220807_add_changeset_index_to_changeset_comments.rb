class AddChangesetIndexToChangesetComments < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    remove_index :changeset_comments, [:author_id, :created_at]
    add_index :changeset_comments, [:changeset_id, :created_at], :algorithm => :concurrently
  end
end
