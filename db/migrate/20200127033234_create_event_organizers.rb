class CreateEventOrganizers < ActiveRecord::Migration[6.0]
  def change
    create_table :event_organizers do |t|
      t.references :event, :foreign_key => true
      t.references :user, :foreign_key => true

      t.timestamps
    end
  end
end
