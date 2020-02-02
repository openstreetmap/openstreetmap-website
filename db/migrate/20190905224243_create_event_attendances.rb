class CreateEventAttendances < ActiveRecord::Migration[5.2]
  def change
    create_table :event_attendances do |t|
      t.references :user, :foreign_key => true, :null => false
      t.references :event, :foreign_key => true, :null => false
      t.string :intention, :null => false
      t.timestamps
    end
  end
end
