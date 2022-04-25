class RemoveAuthorNameFromNoteComment < ActiveRecord::Migration[4.2]
  def up
    remove_column :note_comments, :author_name
  end

  def down
    add_column :note_comments, :author_name, :string
  end
end
