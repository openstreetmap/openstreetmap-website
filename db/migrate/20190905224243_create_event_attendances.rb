class CreateEventAttendances < ActiveRecord::Migration[5.2]
  def change
    create_table :event_attendances do |t|
      t.integer :user_id, :null => false, :index => true
      t.integer :event_id, :null => false, :index => true
      t.string :intention, :null => false

      t.timestamps
    end
  end
end

class CreateEventAttendancesFk < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :event_attendances, :user, validate: false
    add_foreign_key :event_attendances, :event, validate: false
  end
end

class ValidateEventAttendancesFk < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key :event_attendances, :user
    validate_foreign_key :event_attendances, :event
  end
end
