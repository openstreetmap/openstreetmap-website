require 'migrate'

class AddForeignKeysToOauthTables < ActiveRecord::Migration
  def self.up
    add_foreign_key :oauth_tokens, [:user_id], :users, [:id]
    add_foreign_key :oauth_tokens, [:client_application_id], :client_applications, [:id]
    add_foreign_key :client_applications, [:user_id], :users, [:id]
  end

  def self.down
    remove_foreign_key :oauth_tokens, [:user_id], :users
    remove_foreign_key :oauth_tokens, [:client_application_id], :client_applications
    remove_foreign_key :client_applications, [:user_id], :users
  end
end
