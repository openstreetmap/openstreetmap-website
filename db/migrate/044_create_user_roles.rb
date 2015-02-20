require "migrate"

class CreateUserRoles < ActiveRecord::Migration
  def self.up
    create_enumeration :user_role_enum, %w(administrator moderator)

    create_table :user_roles do |t|
      t.column :user_id, :bigint, :null => false
      t.column :role, :user_role_enum, :null => false

      t.timestamps
    end

    User.where(:administrator => true).each do |user|
      UserRole.create(:user_id => user.id, :role => "administrator")
    end

    remove_column :users, :administrator

    add_foreign_key :user_roles, :users, :name => "user_roles_user_id_fkey"
  end

  def self.down
    add_column :users, :administrator, :boolean, :default => false, :null => false

    UserRole.where(:role => "administrator").each do |role|
      user = User.find(role.user_id)
      user.administrator = true
      user.save!
    end

    drop_table :user_roles
    drop_enumeration :user_role_enum
  end
end
