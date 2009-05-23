require 'lib/migrate'

class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages, innodb_table do |t|
      t.string :code, :limit => 5, :null => false
      t.string :name, :null => false
      t.boolean :translation_available, :null => false, :default => false
    end

    add_primary_key :languages, [:code]

    Language.create do |l|
      l.code = 'en'
      l.name = 'English'
      l.translation_available = true
    end

    add_foreign_key :users, [:locale], :languages, [:code]
    add_foreign_key :diary_entries, [:language], :languages, [:code]    
  end

  def self.down
    raise IrreversibleMigration.new
  end
end

