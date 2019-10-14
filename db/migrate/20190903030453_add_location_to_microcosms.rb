class AddLocationToMicrocosms < ActiveRecord::Migration[5.2]
  def change
    change_table "microcosms", :bulk => true do |t|
      t.string "location", :null => false
      t.decimal "lat", :null => false
      t.decimal "lon", :null => false
      t.integer "min_lat", :null => false
      t.integer "max_lat", :null => false
      t.integer "min_lon", :null => false
      t.integer "max_lon", :null => false
    end
  end
end
