class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :title
      t.datetime :moment
      t.string :location
      t.text :description
      t.integer :microcosm_id

      t.timestamps
    end
  end
end
