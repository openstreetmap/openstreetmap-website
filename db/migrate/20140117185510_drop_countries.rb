class DropCountries < ActiveRecord::Migration[4.2]
  def up
    drop_table :countries
  end
end
