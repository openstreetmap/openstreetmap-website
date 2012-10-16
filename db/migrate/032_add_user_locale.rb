# encoding: utf-8

class AddUserLocale < ActiveRecord::Migration
  def self.up
    add_column "users", "locale", :string
  end

  def self.down
    remove_column "users", "locale"
  end
end
