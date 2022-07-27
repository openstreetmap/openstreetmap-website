class RemoveUserImages < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :users, :image_file_name, :image
      remove_column :users, :image_fingerprint, :string
      remove_column :users, :image_content_type, :string
    end
  end
end
