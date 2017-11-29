class AddUserImageFingerprint < ActiveRecord::Migration[5.0]
  def up
    add_column :users, :image_fingerprint, :string, :null => true

    User.where("image_file_name IS NOT NULL").find_each do |user|
      image = user.image

      user.image_fingerprint = image.generate_fingerprint(image)
      user.save!
    end
  end

  def down
    remove_column :users, :image_fingerprint
  end
end
