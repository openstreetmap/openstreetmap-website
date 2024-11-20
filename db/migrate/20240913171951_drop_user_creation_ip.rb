class DropUserCreationIp < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :users, :creation_ip, :string }
  end
end
