class AddEmailValid < ActiveRecord::Migration[5.0]
  def self.up
    add_column "users", "email_valid", :boolean, :default => false, :null => false
    User.update_all("email_valid = (active != 0)") # email_valid is :boolean, but active is :integer. "email_valid = active" (see r11802 or earlier) will fail for stricter dbs than mysql
  end

  def self.down
    remove_column "users", "email_valid"
  end
end
