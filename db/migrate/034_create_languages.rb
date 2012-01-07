require 'migrate'

class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages, innodb_table do |t|
      t.string :code, :null => false
      t.string :english_name, :null => false
      t.string :native_name
    end

    add_primary_key :languages, [:code]

    Language.load("#{Rails.root}/config/languages.yml")

    add_foreign_key :users, [:locale], :languages, [:code]
    add_foreign_key :diary_entries, [:language_code], :languages, [:code]    
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
