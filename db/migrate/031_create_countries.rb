require 'migrate'
require 'rexml/document'

class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries, innodb_table do |t|
      t.column :id,      :integer_pk,              :null => false
      t.column :code,    :string,     :limit => 2, :null => false
      t.column :min_lat, :double,                  :null => false
      t.column :max_lat, :double,                  :null => false
      t.column :min_lon, :double,                  :null => false
      t.column :max_lon, :double,                  :null => false
    end

    add_index :countries, [:code], :name => "countries_code_idx", :unique => true
  end

  def self.down
    drop_table :countries
  end
end
