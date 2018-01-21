class DropCountries < ActiveRecord::Migration[5.0]
  def up
    drop_table :countries
  end
end
