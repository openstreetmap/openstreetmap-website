class RoleInMicrocosmShouldBeUnique < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :microcosm_members, [:microcosm_id, :user_id, :role], :unique => true, :algorithm => :concurrently
  end
end
