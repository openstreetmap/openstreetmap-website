# frozen_string_literal: true

class TileUsers < ActiveRecord::Migration[5.1]
  class User < ApplicationRecord
  end

  def up
    add_column :users, :home_tile, :bigint
    add_index :users, [:home_tile], :name => "users_home_idx"

    User.all.each(&:save!)
  end

  def down
    remove_index :users, :name => "users_home_idx"
    remove_column :users, :home_tile
  end
end
