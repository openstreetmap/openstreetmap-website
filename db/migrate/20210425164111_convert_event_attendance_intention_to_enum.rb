class ConvertEventAttendanceIntentionToEnum < ActiveRecord::Migration[6.0]
  def up
    # This is safe because the
    safety_assured do
      rename_column(:event_attendances, :intention, :intention_orig)
      create_enumeration :event_attendance_intention_enum, %w[maybe no yes]
      # Need to create this with a default to ensure not null.
      add_column(:event_attendances, :intention, :event_attendance_intention_enum, :default => "maybe")
      # Then clobber the value
      EventAttendance.update_all("intention = intention_orig::event_attendance_intention_enum")
      change_column_default(:event_attendances, :intention, nil)
      remove_column(:event_attendances, :intention_orig)
    end
  end

  def down
    safety_assured do
      add_column(:event_attendances, :intention_orig, :string, :default => "maybe", :null => false)
      EventAttendance.update_all("intention_orig = intention")
      change_column_default(:event_attendances, :intention_orig, nil)
      remove_column(:event_attendances, :intention)
      drop_enumeration :event_attendance_intention_enum
      rename_column(:event_attendances, :intention_orig, :intention)
    end
  end
end
