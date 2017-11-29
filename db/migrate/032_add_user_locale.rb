class AddUserLocale < ActiveRecord::Migration[5.0]
  def self.up
    add_column "users", "locale", :string
  end

  def self.down
    remove_column "users", "locale"
  end
end
