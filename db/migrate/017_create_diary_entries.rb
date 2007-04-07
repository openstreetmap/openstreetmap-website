class CreateDiaryEntries < ActiveRecord::Migration
  def self.up
    create_table :diary_entries do |t|
    end
  end

  def self.down
    drop_table :diary_entries
  end
end
