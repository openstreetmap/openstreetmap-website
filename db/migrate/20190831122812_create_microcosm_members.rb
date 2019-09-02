class CreateMicrocosmMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :microcosm_members do |t|
      t.integer :microcosm_id, null: false, index: true
      t.integer :user_id, null: false, index: true
      t.string :role, limit: 64

      t.timestamps
    end
  end
end
