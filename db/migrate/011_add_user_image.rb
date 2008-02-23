class AddUserImage < ActiveRecord::Migration
  def self.up
    add_column 'users', 'image', 'mediumblob'
  end

  def self.down
    remove_column 'users', 'image'
  end
end
