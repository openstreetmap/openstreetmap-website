class CreateUserMutes < ActiveRecord::Migration[7.0]
  def change
    create_table :user_mutes do |t|
      t.references :owner, :null => false, :index => false
      t.references :subject, :null => false, :index => false

      t.timestamps

      t.foreign_key :users, :column => :owner_id
      t.foreign_key :users, :column => :subject_id

      t.index [:owner_id, :subject_id], :unique => true
    end
  end
end
