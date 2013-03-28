class AddWriteNotesPermission < ActiveRecord::Migration
  def up
    add_column :oauth_tokens, :allow_write_notes, :boolean, :null => false, :default => false
    add_column :client_applications, :allow_write_notes, :boolean, :null => false, :default => false
  end

  def down
    remove_column :client_applications, :allow_write_notes
    remove_column :oauth_tokens, :allow_write_notes
  end
end
