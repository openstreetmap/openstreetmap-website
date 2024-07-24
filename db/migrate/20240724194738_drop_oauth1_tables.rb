class DropOauth1Tables < ActiveRecord::Migration[7.1]
  def up
    drop_table :oauth_nonces
    drop_table :oauth_tokens
    drop_table :client_applications
  end
end
