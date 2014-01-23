class DropCountries < ActiveRecord::Migration
  def change
    drop_table :countries
  end
end
