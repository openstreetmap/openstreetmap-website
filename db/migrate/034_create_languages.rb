require 'lib/migrate'

class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages, innodb_table do |t|
      t.string :code, :null => false
      t.string :english_name, :null => false
      t.string :native_name
    end

    add_primary_key :languages, [:code]

    YAML.load(File.read(RAILS_ROOT + "/config/languages.yml")).each do |k,v|
      Language.create do |l|
        l.code = k
        l.english_name = v["english"]
        l.native_name = v["native"]
      end
    end

    add_foreign_key :users, [:locale], :languages, [:code]
    add_foreign_key :diary_entries, [:language], :languages, [:code]    
  end

  def self.down
    raise IrreversibleMigration.new
  end
end

