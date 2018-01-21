class AddCallbackToOauthTokens < ActiveRecord::Migration[5.0]
  def self.up
    add_column :oauth_tokens, :callback_url, :string
    add_column :oauth_tokens, :verifier, :string, :limit => 20
  end

  def self.down
    remove_column :oauth_tokens, :callback_url
    remove_column :oauth_tokens, :verifier
  end
end
