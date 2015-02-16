class AddOpenId < ActiveRecord::Migration
  def self.up
    add_column :users, :openid_url, :string
    add_index :users, [:openid_url], :name => "user_openid_url_idx", :unique => true
  end

  def self.down
    remove_index :users, :name => "user_openid_url_idx"
    remove_column :users, :openid_url
  end
end
