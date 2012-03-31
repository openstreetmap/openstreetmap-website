require 'migrate'

class AddUserAndDescriptionToRedaction < ActiveRecord::Migration
  def up
    add_column :redactions, :user_id, :bigint, :null => false
    add_column :redactions, :description_format, :format_enum, :null => false, :default => "markdown"

    add_foreign_key :redactions, [:user_id], :users, [:id]
  end

  def down
    remove_foreign_key :redactions, [:user_id], :users, [:id]

    remove_column :redactions, :description_format
    remove_column :redactions, :user_id
  end
end
