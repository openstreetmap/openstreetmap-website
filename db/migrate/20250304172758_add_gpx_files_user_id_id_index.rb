# frozen_string_literal: true

class AddGpxFilesUserIdIdIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :gpx_files, [:user_id, :id], :algorithm => :concurrently
  end
end
