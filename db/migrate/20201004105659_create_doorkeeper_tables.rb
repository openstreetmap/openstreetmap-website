# frozen_string_literal: true

class CreateDoorkeeperTables < ActiveRecord::Migration[6.0]
  def change
    create_table :oauth_applications do |t|
      t.references :owner, :null => false, :type => :bigint, :polymorphic => true
      t.string :name, :null => false
      t.string :uid, :null => false
      t.string :secret, :null => false
      t.text :redirect_uri, :null => false
      t.string :scopes, :null => false, :default => ""
      t.boolean :confidential, :null => false, :default => true
      t.timestamps :null => false
    end

    add_index :oauth_applications, :uid, :unique => true
    add_foreign_key :oauth_applications, :users, :column => :owner_id, :validate => false

    create_table :oauth_access_grants do |t|
      t.references :resource_owner, :null => false, :type => :bigint
      t.references :application, :null => false, :type => :bigint
      t.string :token, :null => false
      t.integer :expires_in, :null => false
      t.text :redirect_uri, :null => false
      t.datetime :created_at, :null => false
      t.datetime :revoked_at
      t.string :scopes, :null => false, :default => ""
      t.column :code_challenge, :string, :null => true
      t.column :code_challenge_method, :string, :null => true
    end

    add_index :oauth_access_grants, :token, :unique => true
    add_foreign_key :oauth_access_grants, :users, :column => :resource_owner_id, :validate => false
    add_foreign_key :oauth_access_grants, :oauth_applications, :column => :application_id, :validate => false

    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, :index => true, :type => :bigint
      t.references :application, :null => false, :type => :bigint
      t.string :token, :null => false
      t.string :refresh_token
      t.integer :expires_in
      t.datetime :revoked_at
      t.datetime :created_at, :null => false
      t.string :scopes
      t.string :previous_refresh_token, :null => false, :default => ""
    end

    add_index :oauth_access_tokens, :token, :unique => true
    add_index :oauth_access_tokens, :refresh_token, :unique => true
    add_foreign_key :oauth_access_tokens, :users, :column => :resource_owner_id, :validate => false
    add_foreign_key :oauth_access_tokens, :oauth_applications, :column => :application_id, :validate => false
  end
end
