# encoding: utf-8

class AddRefererToUserToken < ActiveRecord::Migration
  def self.up
    add_column :user_tokens, :referer, :text
  end

  def self.down
    remove_column :user_tokens, :referer
  end
end
