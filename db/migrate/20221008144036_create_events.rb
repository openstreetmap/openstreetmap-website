class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :title, :null => false
      t.datetime :moment, :null => false
      t.string :location, :null => false
      t.string :location_url
      t.float :latitude
      t.float :longitude
      t.text :description, :null => false
      t.references :community, :null => false, :foreign_key => true, :index => true

      t.timestamps
    end
  end
end
