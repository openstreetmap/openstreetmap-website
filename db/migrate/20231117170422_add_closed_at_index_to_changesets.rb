class AddClosedAtIndexToChangesets < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :changesets, [:user_id, :closed_at], :algorithm => :concurrently
  end
end
