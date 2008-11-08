class AddEmailValid < ActiveRecord::Migration
  def self.up
    add_column "users", "email_valid", :boolean, :default => false, :null => false
    User.update_all(:email_valid => true)
  end

  def self.down
    remove_column "users", "email_valid"
  end
end
