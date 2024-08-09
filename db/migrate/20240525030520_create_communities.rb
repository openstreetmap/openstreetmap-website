class CreateCommunities < ActiveRecord::Migration[5.2]
  def change
    create_table :communities do |t|
      t.string :name, :null => false
      t.text :description, :null => false
      t.references :organizer, :null => false, :foreign_key => { :to_table => :users }
      t.string :slug, :null => false
      t.string :location, :null => false
      t.float :latitude, :null => false
      t.float :longitude, :null => false
      t.float :min_lat, :null => false
      t.float :max_lat, :null => false
      t.float :min_lon, :null => false
      t.float :max_lon, :null => false
      t.timestamps
      t.index :slug, :unique => true
    end
  end
end
