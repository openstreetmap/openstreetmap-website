class RemoveAuthorNameFromNoteComment < ActiveRecord::Migration[5.0]
  def up
    remove_column :note_comments, :author_name
  end

  def down
    add_column :note_comments, :author_name, :string
  end
end
