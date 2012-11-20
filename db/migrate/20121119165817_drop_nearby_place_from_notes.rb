class DropNearbyPlaceFromNotes < ActiveRecord::Migration
  def up
    remove_column :notes, :nearby_place
  end

  def down
    add_column :notes, :nearby_place, :string
  end
end
