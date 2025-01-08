class AddCreatorIndexToUserBlocks < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    unless index_exists?(:user_blocks, [:creator_id, :id])
      add_index :user_blocks, [:creator_id, :id], algorithm: :concurrently
    end
  end
end