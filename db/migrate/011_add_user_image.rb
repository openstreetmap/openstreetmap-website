class AddUserImage < ActiveRecord::Migration[5.0]
  def self.up
    add_column "users", "image", :text
  end

  def self.down
    remove_column "users", "image"
  end
end
