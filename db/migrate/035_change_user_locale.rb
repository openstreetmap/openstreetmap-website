require "migrate"

class ChangeUserLocale < ActiveRecord::Migration[5.0]
  def self.up
    remove_foreign_key :users, :column => :locale, :name => "users_locale_fkey"

    rename_column :users, :locale, :languages
  end

  def self.down
    rename_column :users, :languages, :locale

    add_foreign_key :users, :languages, :column => :locale, :primary_key => :code, :name => "users_locale_fkey"
  end
end
