class AddRefererToUserToken < ActiveRecord::Migration[4.2]
  def self.up
    add_column :user_tokens, :referer, :text
  end

  def self.down
    remove_column :user_tokens, :referer
  end
end
