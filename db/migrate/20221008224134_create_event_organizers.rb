class CreateEventOrganizers < ActiveRecord::Migration[7.0]
  def change
    create_table :event_organizers do |t|
      t.references :event, :foreign_key => true, :null => false, :index => true
      t.references :user, :foreign_key => true, :null => false, :index => true

      t.timestamps
    end
  end
end
