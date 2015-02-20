require "migrate"

class AddForeignKeysToOauthTables < ActiveRecord::Migration
  def change
    add_foreign_key :oauth_tokens, :users, :name => "oauth_tokens_user_id_fkey"
    add_foreign_key :oauth_tokens, :client_applications, :name => "oauth_tokens_client_application_id_fkey"
    add_foreign_key :client_applications, :users, :name => "client_applications_user_id_fkey"
  end
end
