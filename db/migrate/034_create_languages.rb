require 'lib/migrate'

class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.string :language_code, :limit => 5, :null => false
      t.string :name, :null => false
      t.boolean :translation_available, :null => false, :default => false

      t.timestamps
    end
    
    add_index :languages, [:language_code], :unique => true

    Language.create(:language_code => 'en', :name => 'English', :translation_available => true)
    
    add_foreign_key :users, [:locale], :languages, [:language_code]
    add_foreign_key :diary_entries, [:language], :languages, [:language_code]    
  end

  def self.down
    raise IrreversibleMigration.new
  end
end
