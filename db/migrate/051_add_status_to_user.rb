require 'migrate'

class AddStatusToUser < ActiveRecord::Migration
  def self.up
    create_enumeration :user_status_enum, ["pending","active","confirmed","suspended","deleted"]

    add_column :users, :status, :user_status_enum, :null => false, :default => "pending"

    User.update_all("status = 'deleted'", { :visible => false })
    User.update_all("status = 'pending'", { :visible => true, :active => 0 })
    User.update_all("status = 'active'", { :visible => true, :active => 1 })

    remove_column :users, :active
    remove_column :users, :visible
  end

  def self.down
    add_column :users, :visible, :boolean, :default => true, :null => false
    add_column :users, :active, :integer, :default => 0, :null => false

    User.update_all("visible = true, active = 1", { :status => "active" })
    User.update_all("visible = true, active = 0", { :status => "pending" })
    User.update_all("visible = false, active = 1", { :status => "deleted" })

    remove_column :users, :status

    drop_enumeration :user_status_enum
  end
end
