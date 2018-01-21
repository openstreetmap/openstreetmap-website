class AddAdminFlag < ActiveRecord::Migration[5.0]
  def self.up
    add_column "users", "administrator", :boolean, :default => false, :null => false
  end

  def self.down
    remove_column "users", "administrator"
  end
end
