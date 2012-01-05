require 'migrate'

class ChangeUserLocale < ActiveRecord::Migration
  def self.up
    remove_foreign_key :users, [:locale], :languages, [:code]

    rename_column :users, :locale, :languages
  end

  def self.down
    rename_column :users, :languages, :locale

    add_foreign_key :users, [:locale], :languages, [:code]
  end
end
