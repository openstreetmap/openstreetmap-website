class ChangeNoteAddressToInet < ActiveRecord::Migration
  def up
    execute "ALTER TABLE note_comments ALTER COLUMN author_ip TYPE inet USING CAST(author_ip AS inet)"
  end

  def down
    change_column :note_comments, :author_ip, :string
  end
end
