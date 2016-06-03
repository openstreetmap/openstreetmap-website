class UpdateOauth < ActiveRecord::Migration
  def up
  	add_column :oauth_tokens, :callback_url, :string
    add_column :oauth_tokens, :verifier, :string, :limit => 20
    add_column :oauth_tokens, :scope, :string
    add_column :oauth_tokens, :valid_to, :timestamp
  end

  def down
    remove_column :oauth_tokens, :valid_to
    remove_column :oauth_tokens, :scope
  end
end
