class RenameOpenidUrl < ActiveRecord::Migration[4.2]
  class User < ActiveRecord::Base
  end

  def change
    rename_column :users, :openid_url, :auth_uid
    add_column :users, :auth_provider, :string

    User.where.not(:auth_uid => nil).update_all(:auth_provider => "openid")

    add_index :users, [:auth_provider, :auth_uid], :unique => true, :name => "users_auth_idx"
    remove_index :users, :column => :auth_uid, :unique => true, :name => "user_openid_url_idx"
  end
end
