class CreateNoteTags < ActiveRecord::Migration[7.2]
  def change
    # Create a table, primary and foreign keys
    create_table :note_tags, :primary_key => [:note_id, :k] do |t|
      t.column "note_id", :bigint, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false

      t.foreign_key :notes, :column => :note_id, :name => "note_tags_id_fkey"
    end
  end
end
