class RemoveAuthorNameFromNoteComment < ActiveRecord::Migration
  def up
    remove_column :note_comments, :author_name
  end

  def down
    add_column :note_comments, :author_name, :string
  end
end
