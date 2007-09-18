class TileTracepoints < ActiveRecord::Migration
  def self.up
    add_column "gps_points", "tile", :integer, :null => false, :unsigned => true
    add_index "gps_points", ["tile"], :name => "points_tile_idx"
    remove_index "gps_points", :name => "points_idx"

    Tracepoint.update_all("tile = tile_for_point(latitude, longitude)")
  end

  def self.down
    add_index "gps_points", ["latitude", "longitude"], :name => "points_idx"
    remove_index "gps_points", :name => "points_tile_idx"
    remove_column "gps_points", "tile"
  end
end
