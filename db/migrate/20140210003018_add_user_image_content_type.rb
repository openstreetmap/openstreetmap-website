class AddUserImageContentType < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :image_content_type, :string
  end
end
