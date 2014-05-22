class AddUserImageContentType < ActiveRecord::Migration
  def change
    add_column :users, :image_content_type, :string
  end
end
