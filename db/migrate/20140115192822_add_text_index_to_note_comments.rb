require 'migrate'

class AddTextIndexToNoteComments < ActiveRecord::Migration
  def up
    add_index :note_comments, [], :columns => "to_tsvector('english', body)", :using => "GIN", :name => "index_note_comments_on_body"
  end

  def down
    remove_index :note_comments, :name => "index_note_comments_on_body"
  end
end
