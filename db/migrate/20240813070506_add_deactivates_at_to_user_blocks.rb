class AddDeactivatesAtToUserBlocks < ActiveRecord::Migration[7.1]
  def change
    add_column :user_blocks, :deactivates_at, :timestamp
  end
end
