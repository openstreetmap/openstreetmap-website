class AddOpenIdAuthenticationTables < ActiveRecord::Migration
  def self.up
    create_table :open_id_authentication_associations, :force => true do |t|
      t.integer :issued, :lifetime
      t.string :handle, :assoc_type
      t.binary :server_url, :secret
    end

    create_table :open_id_authentication_nonces, :force => true do |t|
      t.integer :timestamp, :null => false
      t.string :server_url, :null => true
      t.string :salt, :null => false
    end
    
    add_column :users, :openid_url, :string 

    add_index :users, [:openid_url], :name => "user_openid_unique_idx", :unique => true
    add_index :open_id_authentication_associations, [:server_url], :name => "open_id_associations_server_url_idx"
    add_index :open_id_authentication_nonces, [:timestamp], :name => "open_id_nonces_timestamp_idx"
  end

  def self.down
    remove_index :users, :name => "user_openid_unique_idx"
    remove_index :open_id_authentication_associations, :name => "open_id_associations_server_url_idx"
    remove_index :open_id_authentication_nonces, :name => "open_id_nonces_timestamp_idx"
    remove_column :users, :openid_url
    drop_table :open_id_authentication_associations
    drop_table :open_id_authentication_nonces
  end
end
