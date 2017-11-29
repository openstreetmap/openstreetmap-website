require "migrate"
require "rexml/document"

class CreateCountries < ActiveRecord::Migration[5.0]
  def self.up
    create_table :countries, :id => false do |t|
      t.column :id,      :primary_key, :null => false
      t.column :code,    :string, :limit => 2, :null => false
      t.column :min_lat, :float, :limit => 53, :null => false
      t.column :max_lat, :float, :limit => 53, :null => false
      t.column :min_lon, :float, :limit => 53, :null => false
      t.column :max_lon, :float, :limit => 53, :null => false
    end

    add_index :countries, [:code], :name => "countries_code_idx", :unique => true
  end

  def self.down
    drop_table :countries
  end
end
