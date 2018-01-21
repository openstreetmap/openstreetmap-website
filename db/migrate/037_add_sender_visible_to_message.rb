class AddSenderVisibleToMessage < ActiveRecord::Migration[5.0]
  def self.up
    rename_column :messages, :visible, :to_user_visible
    add_column :messages, :from_user_visible, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :messages, :from_user_visible
    rename_column :messages, :to_user_visible, :visible
  end
end
