class AddRefererToUserToken < ActiveRecord::Migration[5.0]
  def self.up
    add_column :user_tokens, :referer, :text
  end

  def self.down
    remove_column :user_tokens, :referer
  end
end
