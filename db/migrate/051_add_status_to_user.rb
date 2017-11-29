require "migrate"

class AddStatusToUser < ActiveRecord::Migration[5.0]
  def self.up
    create_enumeration :user_status_enum, %w[pending active confirmed suspended deleted]

    add_column :users, :status, :user_status_enum, :null => false, :default => "pending"

    User.where(:visible => false).update_all(:status => "deleted")
    User.where(:visible => true, :active => 0).update_all(:status => "pending")
    User.where(:visible => true, :active => 1).update_all(:status => "active")

    remove_column :users, :active
    remove_column :users, :visible
  end

  def self.down
    add_column :users, :visible, :boolean, :default => true, :null => false
    add_column :users, :active, :integer, :default => 0, :null => false

    User.where(:status => "active").update_all(:visible => true, :active => 1)
    User.where(:status => "pending").update_all(:visible => true, :active => 0)
    User.where(:status => "deleted").update_all(:visible => false, :active => 1)

    remove_column :users, :status

    drop_enumeration :user_status_enum
  end
end
