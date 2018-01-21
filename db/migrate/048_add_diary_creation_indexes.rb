class AddDiaryCreationIndexes < ActiveRecord::Migration[5.0]
  def self.up
    add_index :diary_entries, [:created_at], :name => "diary_entry_created_at_index"
    add_index :diary_entries, [:user_id, :created_at], :name => "diary_entry_user_id_created_at_index"
    add_index :diary_entries, [:language_code, :created_at], :name => "diary_entry_language_code_created_at_index"
  end

  def self.down
    remove_index :diary_entries, :name => "diary_entry_language_code_created_at_index"
    remove_index :diary_entries, :name => "diary_entry_user_id_created_at_index"
    remove_index :diary_entries, :name => "diary_entry_created_at_index"
  end
end
