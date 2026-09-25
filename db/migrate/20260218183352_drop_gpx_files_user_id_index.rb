# frozen_string_literal: true

class DropGpxFilesUserIdIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :gpx_files, [:user_id], :name => "gpx_files_user_id_idx"
  end
end
