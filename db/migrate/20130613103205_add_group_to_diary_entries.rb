require 'migrate'

class AddGroupToDiaryEntries < ActiveRecord::Migration
  def up
    add_column :diary_entries, :group_id, :integer
    add_index :diary_entries, [:group_id], :name => "diary_entries_group_id_idx"
    add_foreign_key :diary_entries, [:group_id], :groups, [:id]
  end

  def down
    remove_foreign_key :diary_entries, [:group_id], :groups, [:id]
    remove_index :diary_entries, :name => "diary_entries_group_id_idx"
    remove_column :diary_entries, :group_id
  end
end
