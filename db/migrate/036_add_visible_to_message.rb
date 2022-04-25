class AddVisibleToMessage < ActiveRecord::Migration[4.2]
  def self.up
    add_column :messages, :visible, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :messages, :visible
  end
end
