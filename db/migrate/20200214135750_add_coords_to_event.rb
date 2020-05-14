class AddCoordsToEvent < ActiveRecord::Migration[6.0]
  def change
    change_table :events, :bulk => true do |t|
      t.float :latitude
      t.float :longitude
      t.string :location_url
    end
  end
end
