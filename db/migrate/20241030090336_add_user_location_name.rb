# frozen_string_literal: true

class AddUserLocationName < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :home_location_name, :string
  end
end
