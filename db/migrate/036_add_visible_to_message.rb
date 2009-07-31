class AddVisibleToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :visible, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :messages, :visible
  end
end
