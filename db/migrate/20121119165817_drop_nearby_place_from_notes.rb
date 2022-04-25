class DropNearbyPlaceFromNotes < ActiveRecord::Migration[4.2]
  def up
    remove_column :notes, :nearby_place
  end

  def down
    add_column :notes, :nearby_place, :string
  end
end
