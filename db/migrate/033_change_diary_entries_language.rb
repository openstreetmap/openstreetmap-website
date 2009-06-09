class ChangeDiaryEntriesLanguage < ActiveRecord::Migration
  def self.up
    remove_column "diary_entries", "language"
    add_column "diary_entries", "language_code", :string, :null => false, :default => "en"
  end

  def self.down
    remove_column "diary_entries", "language_code"
    add_column "diary_entries", "language", :string, :limit => 3
  end
end
