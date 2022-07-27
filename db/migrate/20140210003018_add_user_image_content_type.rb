class AddUserImageContentType < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :image_content_type, :string
  end
end
