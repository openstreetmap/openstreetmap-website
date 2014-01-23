class AddCreatedAtIndexToNoteComments < ActiveRecord::Migration
  def change
    add_index :note_comments, :created_at
  end
end
