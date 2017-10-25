class DropNearbyPlaceFromNotes < ActiveRecord::Migration[5.0]
  def up
    remove_column :notes, :nearby_place
  end

  def down
    add_column :notes, :nearby_place, :string
  end
end
