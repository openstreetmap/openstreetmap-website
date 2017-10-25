require "migrate"

class AddUserAndDescriptionToRedaction < ActiveRecord::Migration[5.0]
  def change
    add_column :redactions, :user_id, :bigint, :null => false
    add_column :redactions, :description_format, :format_enum, :null => false, :default => "markdown"

    add_foreign_key :redactions, :users, :name => "redactions_user_id_fkey"
  end
end
