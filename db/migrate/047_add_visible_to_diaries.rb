class AddVisibleToDiaries < ActiveRecord::Migration[5.0]
  def self.up
    add_column :diary_entries, :visible, :boolean, :null => false, :default => true
    add_column :diary_comments, :visible, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :diary_comments, :visible
    remove_column :diary_entries, :visible
  end
end
