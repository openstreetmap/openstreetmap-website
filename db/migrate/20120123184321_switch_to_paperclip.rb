class SwitchToPaperclip < ActiveRecord::Migration[5.0]
  def up
    rename_column :users, :image, :image_file_name
  end

  def down
    rename_column :users, :image_file_name, :image
  end
end
