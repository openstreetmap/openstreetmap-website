# frozen_string_literal: true

class AddNotesUserIdCreatedAtIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :notes, [:user_id, :created_at],
              :algorithm => :concurrently,
              :where => "user_id IS NOT NULL"
  end
end
