class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :title, :null => false
      t.datetime :moment
      t.string :location
      t.text :description
      t.integer :microcosm_id

      t.timestamps
    end
  end
end

class CreateEventsFk < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :events, :microcosm, :validate => false
  end
end

class ValidateEventsFk < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key :events, :microcosm
  end
end
