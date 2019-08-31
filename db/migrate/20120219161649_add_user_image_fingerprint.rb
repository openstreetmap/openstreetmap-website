class AddUserImageFingerprint < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :image_fingerprint, :string, :null => true
  end

  def down
    remove_column :users, :image_fingerprint
  end
end
