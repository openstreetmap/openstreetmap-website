class CreateMicrocosmMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :microcosm_members do |t|
      t.integer :microcosm_id, :null => false, :index => true
      t.integer :user_id, :null => false, :index => true
      t.string :role, :limit => 64, :null => false
      t.timestamps
    end
  end
end

class AddMicrocosmMemberFkToUser < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :microcosm_members, :user, :validate => false
  end
end

class ValidateMicrocosmMemberFkToUser < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key :microcosm_members, :user
  end
end
