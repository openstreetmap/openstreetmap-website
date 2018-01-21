require "migrate"

class CreateLanguages < ActiveRecord::Migration[5.0]
  def change
    create_table :languages, :id => false do |t|
      t.string :code, :null => false
      t.string :english_name, :null => false
      t.string :native_name
    end

    add_primary_key :languages, [:code]

    Language.load(Rails.root.join("config", "languages.yml"))

    add_foreign_key :users, :languages, :column => :locale, :primary_key => :code, :name => "users_locale_fkey"
    add_foreign_key :diary_entries, :languages, :column => :language_code, :primary_key => :code, :name => "diary_entries_language_code_fkey"
  end
end
