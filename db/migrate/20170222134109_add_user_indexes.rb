class AddUserIndexes < ActiveRecord::Migration
  def change
    add_index :oauth_tokens, [:user_id]
    add_index :client_applications, [:user_id]
  end
end
