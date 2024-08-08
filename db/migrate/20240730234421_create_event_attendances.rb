class CreateEventAttendances < ActiveRecord::Migration[7.0]
  def up
    create_enum :event_attendances_intention_enum, %w[Maybe No Yes]
    create_table :event_attendances do |t|
      t.references :user, :foreign_key => true, :null => false, :index => true
      t.references :event, :foreign_key => true, :null => false, :index => true
      t.column :intention, :event_attendances_intention_enum, :null => false

      t.timestamps
    end
    add_index :event_attendances, [:user_id, :event_id], :unique => true
  end

  def down
    drop_table :event_attendances
    drop_enum :event_attendances_intention_enum
  end
end
