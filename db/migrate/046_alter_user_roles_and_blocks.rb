require 'migrate'

class AlterUserRolesAndBlocks < ActiveRecord::Migration
  def self.up
    # the initial granter IDs can be "self" - there are none of these
    # in the current live DB, but there may be some in people's own local
    # copies.
    add_column :user_roles, :granter_id, :bigint
    UserRole.update_all("granter_id = user_id")
    change_column :user_roles, :granter_id, :bigint, :null => false
    add_foreign_key :user_roles, [:granter_id], :users, [:id]

    # make sure that [user_id, role] is unique
    add_index :user_roles, [:user_id, :role], :name => "user_roles_id_role_unique", :unique => true

    # change the user_blocks to have a creator_id rather than moderator_id
    rename_column :user_blocks, :moderator_id, :creator_id

    # change the "end_at" column to the more grammatically correct "ends_at"
    rename_column :user_blocks, :end_at, :ends_at
  end

  def self.down
    remove_column :user_roles, :granter_id
    remove_index :user_roles, :name => "user_roles_id_role_unique"
    rename_column :user_blocks, :creator_id, :moderator_id
    rename_column :user_blocks, :ends_at, :end_at
  end
end
