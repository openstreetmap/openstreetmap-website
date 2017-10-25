class AddCreatedAtIndexToNoteComments < ActiveRecord::Migration[5.0]
  def change
    add_index :note_comments, :created_at
  end
end
