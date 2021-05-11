class CreateMicrocosmMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :microcosm_members do |t|
      t.references :microcosm, :foreign_key => true, :null => false
      t.references :user, :foreign_key => true, :null => false
      t.string :role, :limit => 64, :null => false
      t.timestamps
    end
  end
end
