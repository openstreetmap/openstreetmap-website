class AddLocationToMicrocosms < ActiveRecord::Migration[5.2]
  def change
    # This group of migrations for microcosms will be run together.
    safety_assured do
      change_table "microcosms", :bulk => true do |t|
        t.string "location", :null => false
        t.integer "lat", :null => false
        t.integer "lon", :null => false
        t.integer "min_lat", :null => false
        t.integer "max_lat", :null => false
        t.integer "min_lon", :null => false
        t.integer "max_lon", :null => false
      end
    end
  end
end
