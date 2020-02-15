class AddCoordsToEvent < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :latitude, :float
    add_column :events, :longitude, :float
    add_column :events, :location_url, :string
  end
end
