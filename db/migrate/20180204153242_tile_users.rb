class TileUsers < ActiveRecord::Migration[5.1]
  class User < ApplicationRecord
  end

  def up
    add_column :users, :home_tile, :bigint
    add_index :users, [:home_tile], :name => "users_home_idx"

    if ENV["USE_DB_FUNCTIONS"]
      User.update_all("home_tile = tile_for_point(cast(round(home_lat * #{GeoRecord::SCALE}) as integer), cast(round(home_lon * #{GeoRecord::SCALE}) as integer))")
    else
      User.all.each(&:save!)
    end
  end

  def down
    remove_index :users, :name => "users_home_idx"
    remove_column :users, :home_tile
  end
end
