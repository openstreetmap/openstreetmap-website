class AddIndexToSearchableDiaryEntries < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_index :diary_entries, :searchable, :using => :gin, :algorithm => :concurrently
    end
  end

  def down
    safety_assured do
      remove_index :diary_entries, :searchable, :algorithm => :concurrently
    end
  end
end
