class AddReadEmailPermission < ActiveRecord::Migration
  def up
    add_column :oauth_tokens, :allow_read_email, :boolean, :null => false, :default => false
    add_column :client_applications, :allow_read_email, :boolean, :null => false, :default => false
  end

  def down
    remove_column :client_applications, :allow_read_email
    remove_column :oauth_tokens, :allow_read_email
  end
end
