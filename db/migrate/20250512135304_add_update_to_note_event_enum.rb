class AddUpdateToNoteEventEnum < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      execute <<-SQL.squish
        ALTER TYPE note_event_enum ADD VALUE 'updated';
      SQL
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
