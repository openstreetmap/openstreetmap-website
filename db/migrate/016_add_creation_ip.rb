class AddCreationIp < ActiveRecord::Migration
  def self.up
    add_column "users", "creation_ip", :string
  end

  def self.down
    remove_column "users", "creation_ip"
  end
end
