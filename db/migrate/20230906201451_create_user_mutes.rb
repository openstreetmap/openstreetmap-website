class CreateUserMutes < ActiveRecord::Migration[7.0]
  def change
    create_table :user_mutes do |t|
      t.references :creator, null: false
      t.references :appointee, null: false

      t.timestamps

      t.foreign_key :users, column: :creator_id
      t.foreign_key :users, column: :appointee_id

      t.index %i[creator_id appointee_id], unique: true
    end
  end
end
