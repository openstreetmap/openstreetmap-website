# frozen_string_literal: true

class RestoreAuthorIndexToChangesetComments < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :changeset_comments, [:author_id, :created_at], :algorithm => :concurrently
  end
end
