class AddTextIndexToNotes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :notes, "to_tsvector('english', description)", :using => "GIN", :name => "index_notes_on_description", :algorithm => :concurrently
  end
end
