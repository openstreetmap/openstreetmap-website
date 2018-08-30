require "migrate"

class CreateUserMemberships < ActiveRecord::Migration[5.1]
  def self.up
    create_enumeration :user_membership_enum, %w[OSMF]

    create_table :user_memberships do |t|
      t.column :user_id, :bigint, :null => false
      t.column :membership, :user_membership_enum, :null => false
      t.column :show, :boolean, :default => false, :null => false
    end

    add_foreign_key :user_memberships, :users, :name => "user_memberships_user_id_fkey"
  end

  def self.down
    drop_table :user_memberships
    drop_enumeration :user_membership_enum
  end
end
