class CreateEventAttendances < ActiveRecord::Migration[5.2]
  def change
    create_table :event_attendances do |t|
      t.integer :user_id
      t.integer :event_id
      t.string :intention

      t.timestamps
    end
  end
end
