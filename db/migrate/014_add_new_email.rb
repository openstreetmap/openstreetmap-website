class AddNewEmail < ActiveRecord::Migration
  def self.up
    add_column "users", "new_email", :string
  end

  def self.down
    remove_column "users", "new_email"
  end
end
