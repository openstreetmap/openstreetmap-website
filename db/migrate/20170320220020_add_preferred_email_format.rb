require "migrate"

class AddPreferredEmailFormat < ActiveRecord::Migration
  def change
    create_enumeration :email_format_enum, %w(text_only multipart)
    add_column :users, :preferred_email_format, :email_format_enum, :null => false, :default => "multipart"
  end
end
