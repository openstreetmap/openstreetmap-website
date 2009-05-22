class AddUserLocale < ActiveRecord::Migration
  def self.up
    add_column "users", "locale", :string, :default => "en", :null => false
  end

  def self.down
    remove_column "users", "locale"
  end
end
