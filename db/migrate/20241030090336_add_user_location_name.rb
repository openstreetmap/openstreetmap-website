class AddUserLocationName < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :location_name, :string
  end
end
