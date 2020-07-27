class AttendanceToEventShouldBeUnique < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :event_attendances, [:user_id, :event_id], :unique => true, :algorithm => :concurrently
  end
end
