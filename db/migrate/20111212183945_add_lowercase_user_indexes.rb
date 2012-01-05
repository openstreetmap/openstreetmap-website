require 'migrate'

class AddLowercaseUserIndexes < ActiveRecord::Migration
  def up
    add_index :users, :display_name, :lowercase => true, :name => "users_display_name_lower_idx"
    add_index :users, :email, :lowercase => true, :name => "users_email_lower_idx"
  end

  def down
    remove_index :users, :name => "users_email_lower_idx"
    remove_index :users, :name => "users_display_name_lower_idx"
  end
end
