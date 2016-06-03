require "migrate"

class CreateUserRoles < ActiveRecord::Migration
  def self.up
    create_enumeration :user_role_enum, %w(administrator moderator)

    create_table :user_roles do |t|
      t.column :user_id, :bigint, :null => false
      t.column :role, :user_role_enum, :null => false
      t.column :granter_id, :bigint, :null => false
  
      t.timestamps :null => true
    end

    add_foreign_key :user_roles, :users, :name => "user_roles_user_id_fkey"
    add_foreign_key :user_roles, :users, :column => :granter_id, :name => "user_roles_granter_id_fkey"

    # make sure that [user_id, role] is unique
    add_index :user_roles, [:user_id, :role], :name => "user_roles_id_role_unique", :unique => true


  end

  def self.down
    drop_table :user_roles
    drop_enumeration :user_role_enum
  end
end
