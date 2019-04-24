require "migrate"

class AddLowercaseUserIndexes < ActiveRecord::Migration[4.2]
  def up
    add_index :users, [], :columns => "LOWER(display_name)", :name => "users_display_name_lower_idx"
    add_index :users, [], :columns => "LOWER(email)", :name => "users_email_lower_idx"
  end

  def down
    remove_index :users, :name => "users_email_lower_idx"
    remove_index :users, :name => "users_display_name_lower_idx"
  end
end
