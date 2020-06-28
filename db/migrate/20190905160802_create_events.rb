class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :title, :null => false
      t.datetime :moment
      t.string :location
      t.text :description
      t.references :microcosm, :foreign_key => true, :null => false
      t.timestamps
    end
  end
end
