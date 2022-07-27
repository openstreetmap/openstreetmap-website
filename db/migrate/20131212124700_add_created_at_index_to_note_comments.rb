class AddCreatedAtIndexToNoteComments < ActiveRecord::Migration[4.2]
  def change
    add_index :note_comments, :created_at
  end
end
