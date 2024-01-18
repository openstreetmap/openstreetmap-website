class DropLowercaseUserIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, "LOWER(display_name)", :name => "users_display_name_lower_idx"
  end
end
