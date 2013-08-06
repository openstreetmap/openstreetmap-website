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

    Net::HTTP.start('ws.geonames.org') do |http|
      xml = REXML::Document.new(http.get("/countryInfo").body)

      xml.elements.each("geonames/country") do |ele|
        code = ele.get_text("countryCode").to_s
        minlon = ele.get_text("bBoxWest").to_s
        minlat = ele.get_text("bBoxSouth").to_s
        maxlon = ele.get_text("bBoxEast").to_s
        maxlat = ele.get_text("bBoxNorth").to_s

        Country.create(
          :code => code,
          :min_lat => minlat.to_f, :max_lat => maxlat.to_f,
          :min_lon => minlon.to_f, :max_lon => maxlon.to_f
        )
      end
    end
  end

  def self.down
    drop_table :countries
  end
end
