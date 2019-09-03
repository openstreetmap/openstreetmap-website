class RoleInMicrocosmShouldBeNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :microcosm_members, :role, false
  end
end


class RoleInMicrocosmShouldBeUnique < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :microcosm_members, [:microcosm_id, :user_id, :role], unique: true, algorithm: :concurrently
  end
end
