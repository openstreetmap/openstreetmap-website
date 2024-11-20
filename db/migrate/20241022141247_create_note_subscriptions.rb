class CreateNoteSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :note_subscriptions, :primary_key => [:user_id, :note_id] do |t|
      t.references :user, :foreign_key => true, :index => false
      t.references :note, :foreign_key => true
    end
  end
end
