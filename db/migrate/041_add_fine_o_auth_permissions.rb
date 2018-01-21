class AddFineOAuthPermissions < ActiveRecord::Migration[5.0]
  PERMISSIONS = [:allow_read_prefs, :allow_write_prefs, :allow_write_diary, :allow_write_api, :allow_read_gpx, :allow_write_gpx].freeze

  def self.up
    PERMISSIONS.each do |perm|
      # add fine-grained permissions columns for OAuth tokens, allowing people to
      # give permissions to parts of the site only.
      add_column :oauth_tokens, perm, :boolean, :null => false, :default => false

      # add fine-grained permissions columns for client applications, allowing the
      # client applications to request particular privileges.
      add_column :client_applications, perm, :boolean, :null => false, :default => false
    end
  end

  def self.down
    PERMISSIONS.each do |perm|
      remove_column :oauth_tokens, perm
      remove_column :client_applications, perm
    end
  end
end
