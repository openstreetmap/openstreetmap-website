class CreateOauthTables < ActiveRecord::Migration
  def self.up
    create_table :client_applications do |t|
      t.string :name
      t.string :url
      t.string :support_url
      t.string :callback_url
      t.string :key, :limit => 50
      t.string :secret, :limit => 50
      t.integer :user_id

      t.timestamps :null => true
    end
    add_index :client_applications, :key, :unique => true

    create_table :oauth_tokens do |t|
      t.integer :user_id
      t.string :type, :limit => 20
      t.integer :client_application_id
      t.string :token, :limit => 50
      t.string :secret, :limit => 50
      t.timestamp :authorized_at, :invalidated_at
      t.timestamps :null => true
      t.column :callback_url, :string
      t.column :verifier, :string, :limit => 20
      t.column :scope, :string
      t.column :valid_to, :timestamp
    end
 

    add_index :oauth_tokens, :token, :unique => true

    create_table :oauth_nonces do |t|
      t.string :nonce
      t.integer :timestamp

      t.timestamps :null => true
    end
    add_index :oauth_nonces, [:nonce, :timestamp], :unique => true
 
 
     PERMISSIONS = [:allow_read_prefs, :allow_write_prefs, :allow_write_diary,
                 :allow_write_api, :allow_read_gpx, :allow_write_gpx].freeze

    PERMISSIONS.each do |perm|
      # add fine-grained permissions columns for OAuth tokens, allowing people to
      # give permissions to parts of the site only.
      add_column :oauth_tokens, perm, :boolean, :null => false, :default => false

      # add fine-grained permissions columns for client applications, allowing the
      # client applications to request particular privileges.
      add_column :client_applications, perm, :boolean, :null => false, :default => false
    end
 
   add_column :oauth_tokens, :allow_write_notes, :boolean, :null => false, :default => false
   add_column :client_applications, :allow_write_notes, :boolean, :null => false, :default => false

    add_foreign_key :oauth_tokens, :users, :name => "oauth_tokens_user_id_fkey"
    add_foreign_key :oauth_tokens, :client_applications, :name => "oauth_tokens_client_application_id_fkey"
    add_foreign_key :client_applications, :users, :name => "client_applications_user_id_fkey"


  end

  def self.down
    drop_table :client_applications
    drop_table :oauth_tokens
    drop_table :oauth_nonces
  end
end
