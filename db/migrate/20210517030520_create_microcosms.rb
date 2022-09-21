class CreateMicrocosms < ActiveRecord::Migration[5.2]
  def change
    create_table :microcosms do |t|
      t.string :name, :null => false
      t.text :description, :null => false
      t.references :organizer, :null => false, :foreign_key => { :to_table => :users }
      t.string :slug, :null => false, :index => { :unique => true }
      t.string :location, :null => false
      t.float :latitude, :null => false
      t.float :longitude, :null => false
      t.float :min_lat, :null => false
      t.float :max_lat, :null => false
      t.float :min_lon, :null => false
      t.float :max_lon, :null => false

      t.timestamps
    end
  end
end
