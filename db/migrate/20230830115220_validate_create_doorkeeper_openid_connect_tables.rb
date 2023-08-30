class ValidateCreateDoorkeeperOpenidConnectTables < ActiveRecord::Migration[7.0]
  # Validate foreign key created by CreateDoorkeeperOpenidConnectTables
  def change
    validate_foreign_key :oauth_openid_requests, :oauth_access_grants
  end
end
