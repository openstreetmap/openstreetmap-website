class DropCountries < ActiveRecord::Migration
  def up
    drop_table :countries
  end
end
