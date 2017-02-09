class AddReadEmailPermission < ActiveRecord::Migration
  def change
    add_column :oauth_tokens, :allow_read_email, :boolean, :null => false, :default => false
    add_column :client_applications, :allow_read_email, :boolean, :null => false, :default => false
  end
end
